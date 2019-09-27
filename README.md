## 项目适用须知

本项目适合Android/IOS手机平板通用型项目，适合开发环境下调试和真机测试；
本地插件在ionic项目基础插件上仅添加APP版本查询，Android安装包下载升级（默认不包含，可选）功能。对比其他ionic项目如下：
1. mes项目不支持包名修改，支持插件功能：本地版本、自动升级插件、截图、系统分享；
2. TVtemplates项目，支持插件功能：本地版本、自动升级插件、外，默认横屏显示和遥控器操作，适合电视看板项目；
3. cardReader项目，在TVTemplates项目基础上还支持插件功能：获取IP地址、获取MAC地址、音频播放、网络状态检测、禁用键盘输入、简单http服务，属于电视看板应用
4. productionLineBoard项目，在TVTemplates项目基础上还支持插件：获取IP地址、获取MAC地址、网络状态检测、网速检测、禁用键盘输入、三色灯连接控制，属于电视看板应用
5. 默认仅支持APP版本插件，升级功能建议通过浏览器下载更新，参考cnc项目的appUpdate服务；使用-u参数编译时可以添加支持Android应用内安装包下载更新。

## 使用

`cdvci.sh`脚本为Android开发环境下在V1项目中辅助调试和开发过程，建议开发流程如下：
```bash
# $app为待开发项目文件名
cd D:/wwl/Develop/Android/$app
svn up
#注意www重名问题
cp www D:/wwl/Develop/ionic/v1/www
#浏览器开发调试并修改OK
ionic serve
#修改D:/wwl/Develop/Android/$app下的config.xml文件版本信息，然后执行`./cdvci.sh`脚本进行真机调试和生成安装包
```
可通过执行`bash cdvci.sh`脚本实现以下功能： 
1. 查看帮助：`./cdvci.sh -h`
2. 真机运行安装cnc项目：`./cdvci.sh cnc run`
3. 浏览器升级下编译cnc项目调试包：`./cdvci.sh cnc build -b`
4. 浏览器升级下签发cnc项目发布包：`./cdvci.sh cnc build -b -r`
5. Android应用内升级功能下编译rwDataCol项目：`./cdvci.sh rwDataCol build -u`

*todo: 写个POWERSHELL版脚本：`.\cdvci.ps1`*

在Android发布，反复迭代开发并测试成功后，如需继续生成IOS版本，可参考以下开发流程：
```bash
#开发环境提交svn
cd D:/wwl/Develop/Android/$app
svn ci -m 'message:xxx'
#切换IOS开发环境，直接进行IOS真机调试及适配工作，进入/home/ionic/v1项目下调用Android/IOS开发脚本./cdvci.sh，示例：
./cdvci.sh rwDataCol prepare -p ios -v 0.1.3 -n 智慧工厂数据中心
#在IOS真机调试OK之后，可以执行导出上传企业版本至fir.im
./cdvci.sh mes upload -p android -v 1.2.9 -n 智慧工厂数据中心 -m "update something"
```

## 安装插件失败后修复
```bash
cordova plugin rm pluginID
cordova platform rm android
cordova platform add android@5.1.1
# 新增文件插件使用@~版本时安装了更高的版本，其依赖android-support-v4:+自动安装的版本过高，会出现aapt的错误。有两种解决办法：
# 1. 指定固定版本，@~去掉~；2. 指定android-support-v4:26.1.0；3.升级android platform版本；
```

## cordova app cors跨域问题
以下所有方法均有安全风险，请酌情评估使用！！！

1. 服务端接口`response headers`添加`Access-Control-Allow-Origin:*`可支持非cookie类接口的所有终端跨域，对于携带cookie的请求必须指定`Access-Control-Allow-Origin:domain`一个特定域名（不支持指定多个）才能支持跨域。但是仍可在服务端判断请求的域名并在返回中请求域名实现支持多域名跨域.
2. Android端可通过白名单插件`cordova plugin add cordova-plugin-whitelist`支持在`config.xml`中配置跨域.
3. `ionic serve`可通过项目内配置文件`ionic.config.json`的`proxies`字段实现指定单个域名跨域.
4. `vue`项目可通过项目内配置文件`vue.config.js`的`devServer.proxy`字段值实现指定单个域名跨域.
5. Ios端只能通过方式一（服务端添加cors）实现跨域支持.
6. 可通过服务端代理脚本支持指定地址自动添加cors支持，参见`proxy.js`代码.
7. chrome浏览器的`Allow-Control-Allow-Origin: *`插件再新版浏览器中已失效.但chrome仍可通过快捷方式的目标中添加` --args --disable-web-security --user-data-dir`的方法实现非安全模式下获取跨域数据用于开发，chrome需要重启后生效