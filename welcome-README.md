# remote www serve project

# project files

- www
- ionic.config.json
- package.json

# ionic cmd
``` 
# -b: dont't open browser
# -a: serve all address 0.0.0.0
# -d: no livereload: port 35729 not open
ionic serve -b -a
```

# web service port
officeNet: 10.6.78.237
proNet: 192.168.11.237
防火墙已开web端口
webServicePorts: 808, 80, 123, 132, 161, 8100, 35729
cmd查看已占用端口
```netstat -ano | findstr :port```
telnet测试端口是否开通
```telnet ip port```