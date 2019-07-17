#!/usr/bin/env bash

# cordova project path, also as script's absolute path
PROJECT_PATH=$(cd "$(dirname "$0")";pwd)
# svn base path, and the directory should be $SOURCE_PATH/$app/www
if [ -z ${SOURCE_PATH} ];then
SOURCE_PATH="/Users/wangweili/Android"
fi
# corporate in app's bundle id
if [ -z ${CORP} ];then
CORP="com.byd"
fi
# `cordova create project` and first run `cordova platform add ios`，the <name> in config.xml for ios can't change. so we save it here
if [ -z ${INITIAL} ];then
INITIAL="cnc"
fi
# fir.im api token
if [ -z ${TOKEN} ];then
TOKEN="0df4b94d3492c6d71836f91b49c918a1"
fi
# project name
app=${1}

# parse arguments
getArgs(){
    i=0
    for var in "$@"; do
        let "i++"
        if [[ $var = "-v" || $var = "--version" ]]
        then
            if [[ -n "${arr[$i]}" && `expr ${arr[$i]} : '^[0-9]*\.[0-9]*'` -ge 3 ]]
            then
                version=${arr[$i]}
                # set version in config
                sed -i ".bk" "s/version[ ]*=[ ]*[\"][^\"]*[\"]/version=\"$version\"/" "$PROJECT_PATH/config.xml"
            else
                # read version in config.xml
                version=`grep -o "version[ ]*=[ ]*[\"][^\"]*[\"]" config.xml | grep -o \".*\"`
                version=${version:1:`expr ${#version} - 2`}
            fi
        elif [[ $var = "-b" || $var = "--build" ]]
        then
            build=${arr[$i]}
        elif [[ $var = "-n" || $var = "--name" ]]
        then
            app_name=${arr[$i]}
        elif [[ $var = "-m" || $var = "--message" ]]
        then
            message=${arr[$i]}
        elif [[ $var = "-p" || $var = "--platform" ]]
        then
            platform=${arr[$i]}
        fi
    done
    if [[ $platform != "ios" && $platform != "android" ]]
    then
        echo "platform invalid, platform could only be android or ios"
        exit
    fi
    if [[ ! -e "$SOURCE_PATH/$app/www" ]];then
        echo "source path: $SOURCE_PATH/$app/www doesn't exist!"
        exit
    fi
}

prepare()
{
    cd "$SOURCE_PATH/$app/www"
    {
        #try
        svn up
    } || {
        # catch
        {
            git pull
        } || {
            echo "$SOURCE_PATH/$app/www CVS code update failed!"
            exit
        }
    }
    if [[ $app = "mes" ]]
    then
        mv .svn ../
    fi
    cd $PROJECT_PATH
    # set bundle id in config.xml
    sed -i ".bk" "s/id[ ]*=[ ]*['|\"][^\"]*['|\"]/id=\"$CORP.$app\"/" config.xml
    if [[ $platform = "ios" ]]
    then
        if [ -n $app_name ]
        then
            sed -i ".bk" "s/<name>[^<]*<\/name>/<name>$app_name<\/name>/" "$PROJECT_PATH/config.xml"
        else
            # read app_name in config.xml
            app_name=`grep -o "<name>[^<]*</name>" config.xml | grep -o '>.*<'`
            app_name=${app_name:1:`expr ${#app_name} - 2`}
        fi
        # set name to $INITIAL in ios project, because ios project don't support name change in config.xml
        sed -i ".bk" "s/$app_name/$INITIAL/" config.xml
        # set app_name to info.plist, change app name in real
        ## grep搜索显示行号和行内容： grep -n CFBundleDisplayName "platforms/ios/$INITIAL/$INITIAL-info.plist"
        line=`sed -n '/CFBundleDisplayName/=' "platforms/ios/$INITIAL/$INITIAL-info.plist"`
        line=`expr $line + 1`
        ## 换行问题，info.plist文件中拷贝换行符在</string>后粘贴才解决
        sed -i ".bk" "${line}c \ 
            <string>$app_name</string>
            " "platforms/ios/$INITIAL/$INITIAL-info.plist"
        echo "set app name: $app_name"
        # fix PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj to avoid Export,Archive Error with Profiles
        sed -i ".bk" "s/PRODUCT_BUNDLE_IDENTIFIER[ ]*=.*;/PRODUCT_BUNDLE_IDENTIFIER = $CORP.$app;/g" "platforms/ios/$INITIAL.xcodeproj/project.pbxproj"
    fi
    #添加www链接
    rm -rf www
    ln -s "$SOURCE_PATH/$app/www" www
}

restore(){
    cd $PROJECT_PATH
    rm www
    rm config.xml.bk
    if [[ $platform = "ios" ]]
    then
        rm "platforms/ios/$INITIAL/$INITIAL-info.plist.bk" "platforms/ios/$INITIAL.xcodeproj/project.pbxproj.bk"
    fi
    if [[ $app = "mes" ]]
    then
        cd "$SOURCE_PATH/mes"
        mv .svn www/
        cd $PROJECT_PATH
    fi
    echo "restore successfully"
}

upload(){
    echo "upload $platform ${1} to fir.im"
    response=`curl -X "POST" "http://api.fir.im/apps" \
     -H "Content-Type: application/json" \
     -d "{\"type\":\"$platform\", \"bundle_id\":\"$CORP.$app\", \"api_token\":\"$TOKEN\"}"`

    if [[ -n $1 && ${1} = "icon" ]]
    then
        key=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.icon.key)" "$response"`
        token=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.icon.token)" "$response"`
        url=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.icon.upload_url)" "$response"`
        key=${key:1:`expr ${#key} - 2`}
        token=${token:1:`expr ${#token} - 2`}
        url=${url:1:`expr ${#url} - 2`}
        # upload icon
        echo `curl -F "key=$key" \
        -F "token=$token"  \
        -F "file=@$PROJECT_PATH/resources/icon.png" \
        $url`
    else
        key=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.binary.key)" "$response"`
        token=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.binary.token)" "$response"`
        url=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.binary.upload_url)" "$response"`
        key=${key:1:`expr ${#key} - 2`}
        token=${token:1:`expr ${#token} - 2`}
        url=${url:1:`expr ${#url} - 2`}
        if [[ $platform = "ios" ]]
        then
            binary_path="$PROJECT_PATH/platforms/ios/build/device/$INITIAL.ipa"
        else
            binary_path="$PROJECT_PATH/platforms/android/app/build/outputs/apk/release/app-release.apk"
        fi
        if [ -z $build ]
        then
            build=$version
        fi
        # upload binary
        echo `curl -F "key=$key" \
        -F "token=$token" \
        -F "file=@$binary_path" \
        -F "x:name=$app_name" \
        -F "x:version=$version" \
        -F "x:build=$build" \
        -F "x:release_type=inhouse" \
        -F "x:changelog=update something" \
        $url`
    fi
}

if [[ -n $app && $app != "--help" && $app != "-h" ]]
then
    # $./cdvci.sh cnc prepare -v 1.abe -b 23 -m 'etveg te ll'，执行时以下方式无法处理参数含空格问题
    # arr=($@)
    # echo ${arr[7]}
    # ${arr[7]}为etveg,以下方式${arr[7]}为etveg te ll
    i=0
    for var in "$@"; do
        arr[$i]=$var
        let "i++"
    done
    # 参数处理
    getArgs $@
    if [[ ${2} = "prepare" || ${2} = "run" || ${2} = "upload"  ]]
    then
        prepare
        if [[ ${2} = "prepare" ]]
        then
            cordova prepare $platform
            restore
        elif [[ ${2} = "run" ]]
        then
            cordova run $platform --device
            restore
        elif [[ ${2} = "upload" ]]
        then
            cordova build $platform --release --device
            restore
            upload
        fi
    elif [[ ${2} = "clean" ]]
    then
        restore
    elif [[ ${2} = "uploadIcon" ]]
    then
        upload icon
    else
        echo "invalid operation"
    fi
else
    echo "cdvci.sh Usage: "
    echo "./cdvci.sh app command [OPTIONS]..."
    echo "  app should be the last name of bundle id, and also the name of a child directory with a www source directory in \$SOURCE_PATH"
    echo "  command could only be as follows:"
    echo "      prepare                     will run cordova prepare platform"
    echo "      run                         will run cordova run platform --device"
    echo "      clean                       will restore project initial files,usually after abnormal command execution without a \"restore successfully\" output"
    echo "      upload                      will run cordova build platform --release --device, and upload binary to fir.im"
    echo "      uploadIcon                  will upload icon to fir.im"
    echo "  -p, --platform <platform>       required, platform value: ios, android"
    echo "  -v, --version <version>         version format: a.b.c, default: 0.0.1"
    echo "  -b, --build <build>             build number for upload command, default: version value"
    echo "  -n, --name <name>               app display name"
    echo "  -m, --message <changelog>       upload changelog, only for upload command, should be without spaces"
    echo "  -h, --help                      see usage"
fi