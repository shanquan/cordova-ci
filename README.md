# 本项目为通用android/ios编译模板,适合生产环境下自动发布

# 前提条件

操作系统： MAC OS X
安装程序：nodejs,xcode,android studio
```bash
npm -i -g cordova ios-sim ios-deploy
# appname:cnc为$INITIAL变量值
cordova create cnc
cordova platform add android
cordova platform add ios
```
变量$INITIAL、$TOKEN配置正确，源码路径配置后的路径为：$SOURCE_PATH/$app/www
源码路径下可以通过`svn up`或`git pull`命令更新；
ios 编译发布还需要先配置好apple id,开发者证书,mobile profile，可以通过先用xcode打开并编译项目进行验证；

## 其他操作系统说明
如果是linux系统并安装好JDK和Android SDK后，仅支持编译和上传android APP；
此脚本不支持windows系统，可转换为相应的powershell脚本或通过linux子系统运行支持android App；
其他操作系统可通过vagrant安装[vagrant osx box](https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=&q=osx)配置虚拟机IOS开发环境；
或者不用此脚本，通过github和Travis CI进行持续集成（支持android和ios），[参考pgyer持续集成文档](https://www.pgyer.com/doc/view/travis_ios).

# IOS platform添加后不能修改config.xml中的name，但是可以修改id
IOS发布后如需修改显示名称，直接在XCODE打开，并选择TARGETS->General，修改Display Name即可；
bundleID改变后有时会因为缓存发布报错，按以下步骤修改bundleID可解决：
1. 在XCODE打开，并选择TARGETS->General，修改Bundle Identifier
2. 选择TARGETS->Info，确认是否需要修改Bundle identifier
3. 选择TARGETS->Build Settings->Packaging，确认是否需要修改Product Bundle Identifier
4. 选择TARGETS->General->Signing，点击Provisioning Profile确认Bundle ID

# cordova ios Info 变量
Bundle name: ${PRODUCT_NAME}
Bundle identifier: $(PRODUCT_BUNDLE_IDENTIFIER) 
Executable file: ${PRODUCT_NAME}

# 编译打包命令
配置[build.json](./build.json)

打包命令
```bash
#此项目直接执行cordova命令前，需确认www文件夹存在，以及config.xml中的name值为cnc初始值不能修改
#真机调试
cordova run ios --device
#手动安装ipa
cordova build ios --device
cd ~/ionic1/platforms/ios/build/device
ios-deploy --debug --bundle cnc.ipa
#模拟器调试
cordova run ios --emulator
#导出企业版
cordova build ios --release --device
#修改config.xml中的id并重新编译，遇到找不到profile问题，需修改platforms/ios/cnc.xcodeproj/project.pbxproj文件中的Product Bundle Identifier
sed -i ".bk" "s/com.byd.cnc/com.byd.mes/" platforms/ios/cnc.xcodeproj/project.pbxproj
```

CI脚本 cdvci.sh

```bash
#脚本添加执行权限
chmod +x cdvci.sh
#查看脚本用法
./cdvci.sh -h
#构建svn app command [OPTIONS].
./cdvci.sh mes prepare -p ios -v 0.1.3
#真机调试  前提：
# usb连接iphone，iphone信任设备，且解锁
# android开启USB调试
./cdvci.sh mes run -p ios -n 智慧工厂数据中心
#假如命令(如真机调试)后，未正常restore（没有echo "restore successfully"）,则需马上手动restore执行以下命令
./cdvci.sh mes clean -p ios
#导出并上传企业版
#set proxy
export http_proxy=http://10.9.26.13:8080 && \
export https_proxy=http://10.9.26.13:8080 && \
export no_proxy=10.0.0.0/24,loalhost,127.0.0.1,*.byd.com,*.byd.com.cn
./cdvci.sh mes upload -p android -v 1.2.9 -n 智慧工厂数据中心 -m "update something"
#仅上传应用图标
./cdvci.sh mes uploadIcon -p ios
```

# ios-deploy
安装：`npm i -g ios-deploy`
使用：`ios-deploy`查看使用说明，功能类似于android的adb

# fir.im upload log
<http://fir.im/docs/publish>

get upload tokens request sample
```bash
curl -X "POST" "http://api.fir.im/apps" \
     -H "Content-Type: application/json" \
     -d "{\"type\":\"ios\", \"bundle_id\":\"com.byd.cnc\", \"api_token\":\"0df4b94d3492c6d71836f91b49c918a1\"}"
```
response sample
```json
{
    "id": "5b165289ca87a8535507fff4",
    "type": "ios",
    "short": "fyqa",
    "app_user_id": "57a40a34959d692e740000ec",
    "storage": "qiniu",
    "form_method": "POST",
    "cert": {
        "icon": {
            "key": "6ea4b130767d97e8c2827241e0a22a2532886ccf",
            "token": "LOvmia8oXF4xnLh0IdH05XMYpH6ENHNpARlmPc-T:X_qz8egXbRWjwJrKzNYuXi6k9JQ=:eyJzY29wZSI6ImZpcmljb246NmVhNGIxMzA3NjdkOTdlOGMyODI3MjQxZTBhMjJhMjUzMjg4NmNjZiIsImNhbGxiYWNrVXJsIjoiaHR0cDovL2FwaS5maXIuaW0vYXV0aC9xaW5pdS9jYWxsYmFjaz9wYXJlbnRfaWQ9NWIxNjUyODljYTg3YTg1MzU1MDdmZmY0XHUwMDI2dGltZXN0YW1wPTE1NjI5MTE4MThcdTAwMjZzaWduPTcxYWI2XHUwMDI2b3JpZ2luYWxfa2V5PWQ1NWQ5ZTc0YjBlYzQ2OGZlM2ZiYTA3NjIyOGEyZTI1N2IzYmVjYzciLCJjYWxsYmFja0JvZHkiOiJrZXk9JChrZXkpXHUwMDI2ZXRhZz0kKGV0YWcpXHUwMDI2ZnNpemU9JChmc2l6ZSlcdTAwMjZmbmFtZT0kKGZuYW1lKVx1MDAyNm9yaWdpbj0kKHg6b3JpZ2luKVx1MDAyNmlzX2NvbnZlcnRlZD0kKHg6aXNfY29udmVydGVkKSIsImRlYWRsaW5lIjoxNTYyOTEyNDE4LCJ1cGhvc3RzIjpbImh0dHA6Ly91cC5xaW5pdS5jb20iLCJodHRwOi8vdXBsb2FkLnFpbml1LmNvbSIsIi1IIHVwLnFpbml1LmNvbSBodHRwOi8vMTgzLjEzMS43LjMiXSwiZ2xvYmFsIjpmYWxzZX0=",
            "upload_url": "https://upload.qbox.me",
            "custom_headers": {},
            "custom_callback_data": {
                "original_key": "d55d9e74b0ec468fe3fba076228a2e257b3becc7"
            }
        },
        "binary": {
            "key": "a8d2c3919b494cc6e740fb2ceb2cffd61b6105d8",
            "token": "LOvmia8oXF4xnLh0IdH05XMYpH6ENHNpARlmPc-T:Sq3Nbu79t1B3bmlSsmB5_mksLc0=:eyJzY29wZSI6InByby1hcHA6YThkMmMzOTE5YjQ5NGNjNmU3NDBmYjJjZWIyY2ZmZDYxYjYxMDVkOCIsImNhbGxiYWNrVXJsIjoiaHR0cDovL2FwaS5maXIuaW0vYXV0aC9xaW5pdS9jYWxsYmFjaz9wYXJlbnRfaWQ9NWIxNjUyODljYTg3YTg1MzU1MDdmZmY0XHUwMDI2dGltZXN0YW1wPTE1NjI5MTE4MThcdTAwMjZzaWduPTcxYWI2XHUwMDI2dXNlcl9pZD01N2E0MGEzNDk1OWQ2OTJlNzQwMDAwZWMiLCJjYWxsYmFja0JvZHkiOiJrZXk9JChrZXkpXHUwMDI2ZXRhZz0kKGV0YWcpXHUwMDI2ZnNpemU9JChmc2l6ZSlcdTAwMjZmbmFtZT0kKGZuYW1lKVx1MDAyNm9yaWdpbj0kKHg6b3JpZ2luKVx1MDAyNm5hbWU9JCh4Om5hbWUpXHUwMDI2YnVpbGQ9JCh4OmJ1aWxkKVx1MDAyNnZlcnNpb249JCh4OnZlcnNpb24pXHUwMDI2aXNfdXNlX21xYz0kKHg6aXNfdXNlX21xYylcdTAwMjZjaGFuZ2Vsb2c9JCh4OmNoYW5nZWxvZylcdTAwMjZyZWxlYXNlX3R5cGU9JCh4OnJlbGVhc2VfdHlwZSlcdTAwMjZkaXN0cmlidXRpb25fbmFtZT0kKHg6ZGlzdHJpYnV0aW9uX25hbWUpXHUwMDI2c3VwcG9ydGVkX3BsYXRmb3JtPSQoeDpzdXBwb3J0ZWRfcGxhdGZvcm0pXHUwMDI2bWluaW11bV9vc192ZXJzaW9uPSQoeDptaW5pbXVtX29zX3ZlcnNpb24pXHUwMDI2dWlfcmVxdWlyZWRfZGV2aWNlX2NhcGFiaWxpdGllcz0kKHg6dWlfcmVxdWlyZWRfZGV2aWNlX2NhcGFiaWxpdGllcylcdTAwMjZ1aV9kZXZpY2VfZmFtaWx5PSQoeDp1aV9kZXZpY2VfZmFtaWx5KSIsImRlYWRsaW5lIjoxNTYyOTE1NDE4LCJ1cGhvc3RzIjpbImh0dHA6Ly91cC5xaW5pdS5jb20iLCJodHRwOi8vdXBsb2FkLnFpbml1LmNvbSIsIi1IIHVwLnFpbml1LmNvbSBodHRwOi8vMTgzLjEzMS43LjMiXSwiZ2xvYmFsIjpmYWxzZX0=",
            "upload_url": "https://upload.qbox.me",
            "custom_headers": {}
        },
        "mqc": {
            "total": 5,
            "used": 0,
            "is_mqc_availabled": true
        },
        "support": "qiniu",
        "prefix": "x:"
    }
}
```

upload icon request sample
```bash
curl -F "key=dea7fc5be1b3dc0f3746315a2784d64a34b86188" \
    -F "token=LOvmia8oXF4xnLh0IdH05XMYpH6ENHNpARlmPc-T:MEkCP_ccNqLoZFr72PewZ1USCKA=:eyJzY29wZSI6ImZpcmljb246ZGVhN2ZjNWJlMWIzZGMwZjM3NDYzMTVhMjc4NGQ2NGEzNGI4NjE4OCIsImNhbGxiYWNrVXJsIjoiaHR0cDovL2FwaS5maXIuaW0vYXV0aC9xaW5pdS9jYWxsYmFjaz9wYXJlbnRfaWQ9NWQyNmNmNjQyMzM4OWY0MDFjZGI5MzJjXHUwMDI2dGltZXN0YW1wPTE1NjI4MjgwODFcdTAwMjZzaWduPWM2ZDE1XHUwMDI2b3JpZ2luYWxfa2V5PSIsImNhbGxiYWNrQm9keSI6ImtleT0kKGtleSlcdTAwMjZldGFnPSQoZXRhZylcdTAwMjZmc2l6ZT0kKGZzaXplKVx1MDAyNmZuYW1lPSQoZm5hbWUpXHUwMDI2b3JpZ2luPSQoeDpvcmlnaW4pXHUwMDI2aXNfY29udmVydGVkPSQoeDppc19jb252ZXJ0ZWQpIiwiZGVhZGxpbmUiOjE1NjI4Mjg2ODEsInVwaG9zdHMiOlsiaHR0cDovL3VwLnFpbml1LmNvbSIsImh0dHA6Ly91cGxvYWQucWluaXUuY29tIiwiLUggdXAucWluaXUuY29tIGh0dHA6Ly8xODMuMTMxLjcuMyJdLCJnbG9iYWwiOmZhbHNlfQ=="     \
    -F "file=@resources/icon.png" \
    https://upload.qbox.me
```
response sample
```json
{
    "download_url": "https://oivkbuqoc.qnssl.com/dea7fc5be1b3dc0f3746315a2784d64a34b86188?attname=icon.png&e=1562831770&token=LOvmia8oXF4xnLh0IdH05XMYpH6ENHNpARlmPc-T:gL29zPFIxYSH7XjHbkPHtYd5dDQ=",
    "is_completed": true
}
```

upload banary request sample
```bash
curl -F "key=9e9fac976e97db92983df8b2dc7b594d784366d6" \
       -F "token=LOvmia8oXF4xnLh0IdH05XMYpH6ENHNpARlmPc-T:iMsZO-qE2VpvPvF9F37yamENnu8=:eyJzY29wZSI6InByby1hcHA6OWU5ZmFjOTc2ZTk3ZGI5Mjk4M2RmOGIyZGM3YjU5NGQ3ODQzNjZkNiIsImNhbGxiYWNrVXJsIjoiaHR0cDovL2FwaS5maXIuaW0vYXV0aC9xaW5pdS9jYWxsYmFjaz9wYXJlbnRfaWQ9NWQyNmNmNjQyMzM4OWY0MDFjZGI5MzJjXHUwMDI2dGltZXN0YW1wPTE1NjI4MjgwODFcdTAwMjZzaWduPWM2ZDE1XHUwMDI2dXNlcl9pZD01N2E0MGEzNDk1OWQ2OTJlNzQwMDAwZWMiLCJjYWxsYmFja0JvZHkiOiJrZXk9JChrZXkpXHUwMDI2ZXRhZz0kKGV0YWcpXHUwMDI2ZnNpemU9JChmc2l6ZSlcdTAwMjZmbmFtZT0kKGZuYW1lKVx1MDAyNm9yaWdpbj0kKHg6b3JpZ2luKVx1MDAyNm5hbWU9JCh4Om5hbWUpXHUwMDI2YnVpbGQ9JCh4OmJ1aWxkKVx1MDAyNnZlcnNpb249JCh4OnZlcnNpb24pXHUwMDI2aXNfdXNlX21xYz0kKHg6aXNfdXNlX21xYylcdTAwMjZjaGFuZ2Vsb2c9JCh4OmNoYW5nZWxvZylcdTAwMjZyZWxlYXNlX3R5cGU9JCh4OnJlbGVhc2VfdHlwZSlcdTAwMjZkaXN0cmlidXRpb25fbmFtZT0kKHg6ZGlzdHJpYnV0aW9uX25hbWUpXHUwMDI2c3VwcG9ydGVkX3BsYXRmb3JtPSQoeDpzdXBwb3J0ZWRfcGxhdGZvcm0pXHUwMDI2bWluaW11bV9vc192ZXJzaW9uPSQoeDptaW5pbXVtX29zX3ZlcnNpb24pXHUwMDI2dWlfcmVxdWlyZWRfZGV2aWNlX2NhcGFiaWxpdGllcz0kKHg6dWlfcmVxdWlyZWRfZGV2aWNlX2NhcGFiaWxpdGllcylcdTAwMjZ1aV9kZXZpY2VfZmFtaWx5PSQoeDp1aV9kZXZpY2VfZmFtaWx5KSIsImRlYWRsaW5lIjoxNTYyODMxNjgxLCJ1cGhvc3RzIjpbImh0dHA6Ly91cC5xaW5pdS5jb20iLCJodHRwOi8vdXBsb2FkLnFpbml1LmNvbSIsIi1IIHVwLnFpbml1LmNvbSBodHRwOi8vMTgzLjEzMS43LjMiXSwiZ2xvYmFsIjpmYWxzZX0=" \
       -F "file=@platforms/ios/build/device/cnc.ipa" \
       -F "x:name=智慧工厂CNC数据中心" \
       -F "x:version=0.1.2" \
       -F "x:build=0.1.2" \
       -F "x:release_type=inhouse" \
       -F "x:changelog=update something" \
       https://upload.qbox.me
```
response sample
```json
{
    "download_url": "https://pro-app-qn.fir.im/9e9fac976e97db92983df8b2dc7b594d784366d6?attname=cnc.ipa&e=1562831931&token=LOvmia8oXF4xnLh0IdH05XMYpH6ENHNpARlmPc-T:MhP66CNT5Qyy8vfvlxv54q1ZNkk=",
    "is_completed": true,
    "release_id": "5d26de2b23389f401cdb95d3"
}
```
upload icon test sample
```bash

platform=android \
CORP="com.byd" \
TOKEN="0df4b94d3492c6d71836f91b49c918a1" \
app=cnc

response=`curl -X "POST" "http://api.fir.im/apps" \
     -H "Content-Type: application/json" \
     -d "{\"type\":\"$platform\", \"bundle_id\":\"$CORP.$app\", \"api_token\":\"$TOKEN\"}"`

key=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.icon.key)" "$response"`
token=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.icon.token)" "$response"`
url=`node -pe "JSON.stringify(JSON.parse(process.argv[1]).cert.icon.upload_url)" "$response"`
key=${key:1:`expr ${#key} - 2`}
token=${token:1:`expr ${#token} - 2`}
url=${url:1:`expr ${#url} - 2`}

echo `curl -F "key=$key" \
        -F "token=$token"  \
        -F "file=@resources/icon.png" \
        $url`
```
