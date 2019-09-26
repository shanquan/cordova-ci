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