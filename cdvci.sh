# 处理ASDK
asdk(){
  # ${1}=0,改simple为编译ASDK
  SDK_PATH="D:/"
  if [[ -d "$SDK_PATH/ASDK--simple" && ${1} = 0 ]];then
    mv $SDK_PATH/ASDK $SDK_PATH/ASDK--
    mv $SDK_PATH/ASDK--simple $SDK_PATH/ASDK
  # ${1}=1,注释ASDK为ASDK--simple
  elif [ ${1} = 1 ];then
    mv $SDK_PATH/ASDK $SDK_PATH/ASDK--simple
    mv $SDK_PATH/ASDK-- $SDK_PATH/ASDK

  fi
}

# 处理www和config.xml
prepare(){
  if [[ ! -d $PROJECT_PATH/www ]];then
    cp $SOURCE_PATH/$app/www $PROJECT_PATH/www
  fi
  # read app_id in config.xml
  app_id=`grep -o "id[ ]*=[ ]*['|\"][^\"]*['|\"]" "$SOURCE_PATH\/$app\/config.xml" | grep -o \".*\"`
  # set app_id
  sed -i "s/id[ ]*=[ ]*['|\"][^\"]*['|\"]/id=$app_id/" "$PROJECT_PATH/config.xml"
  # read app_name in config.xml
  app_name=`grep -o "<name>[^<]*</name>" "$SOURCE_PATH/$app/config.xml" | grep -o '>.*<'`
  # set app_name
  sed -i "s/<name>[^<]*<\/name>/<name$app_name\/name>/" "$PROJECT_PATH/config.xml"
  # read version in config.xml
  version=`grep -o "<widget.*>" "$SOURCE_PATH/$app/config.xml" | grep -o "version[ ]*=[ ]*[\"][^\"]*[\"]" | grep -o \".*\"`
  # set version, 在2~3行查找匹配
  sed -i "2,3s/version[ ]*=[ ]*[\"][^\"]*[\"]/version=$version/" "$PROJECT_PATH/config.xml"
}

clean(){
  asdk 1
}
# 清理项目

# 处理参数，执行脚本
PROJECT_PATH="D:/wwl/Develop/ionic/v1"
SOURCE_PATH="D:/wwl/Develop/Android"
cd $PROJECT_PATH
app=${1}
params=""
if [[ -n "$app" && $app != "--help" && $app != "-h" ]];then
  if [[ -d $SOURCE_PATH/$app/www && -f  $SOURCE_PATH/$app/config.xml ]];then
    if [[ ${2} = "build" || ${2} = "run" ]];then
      asdk 0
      for var in "$@"; do
          if [[ $var = "-u" || $var = "--update" ]];then
            cordova plugin add cordova-plugin-file@4.2.0 cordova-plugin-file-opener2@2.0.2 cordova-plugin-file-transfer@1.5.1
          elif [[ $var = "-s" || $var = "--simple" ]];then
            cordova plugin remove cordova-plugin-file cordova-plugin-file-opener2 cordova-plugin-file-transfer
          elif [[ $var = "-r" || $var = "--release" ]];then
            params=$var
          fi
      done
      prepare
      echo "cordova ${2} android $params"
      cordova ${2} android $params
      clean
    else
      echo "command invalid, only support command: run or build"
    fi
  else
    echo "app invalid"
  fi
else
    echo "cdvci.sh Usage: "
    echo "./cdvci.sh app command [OPTIONS]..."
    echo "  app should be the name of a child directory with a www source directory and a config.xml file in \$SOURCE_PATH"
    echo "  command could only be as follows:"
    echo "      run                         run cordova run android"
    echo "      build                       run cordova build android"
    echo "  OPTIONS could be as follows:"
    echo "      -r, --release               add --release with cordova run or cordova build"
    echo "      -u, --update                run cordova plugin add before cordova run or cordova build"
    echo "      -s, --simple                run cordova plugin remove before cordova run or cordova build"
    echo "      -h, --help                  see usage"
fi
