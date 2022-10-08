# oracle-single-db-install
本脚本用于Oracle的单机安装



## 支持的操作系统和数据库版本
操作系统：LINUX 6-7
数据库版本：Oracle 11g-19c no-cdb/cdb
源数据库架构：单机

##脚本更新说明
###V2.12
1.增加19c优化参数
2.修复脚本头部内存计算bc调用缺包的问题
3.优化redo日志目录获取逻辑
4.支持yum源手工配置选项
###V2.8
1.适配大内存（shmmax/shmall）
###V2.9
1.修复18c dbca 的bug
2.适配cdb和no-cdb
###V2.10
1.修复脚本中dbca配置错误（12.2.0.1 nocdb createAsContainerDatabase的）
2.增加了关于大页设置脚本生成的函数（gather_hugepages_set_script）

## 使用说明
###前期准备工作
```
 1.上传脚本
 2.上传数据库介质
 3.放置操作系统介质到光驱或者上传操作系统介质，也可以手工配置ftp源
```
###脚本参数说明
```
 -help 获取帮助
 -c 设定dbca建库字符集
 -C 开启创建数据库,设置为Y代表仅安装数据库实例,配合-s使用
 -d 数据库介质上传目录,该参数必须设置
 -D 数据库删除和数据库软件删除，默认：N
 -G 开启debug模式
 -H 设置主机名
 -i 指定本机ip
 -n 指定数据库软件安装时是否创建监听，默认为N
 -o 介质上传目录，默认：/dev/cdrom（光驱），如手工配置完成，则设为F|f，
 -O 数据文件存放位置
 -a 归档日志文件存放位置(并代表已开启)
 -p 设置监听端口，默认:1521
 -P 选择设置cdb模式（Y）或no-cdb模式（N）,默认：N 
 -s 设置数据库名字以及ORACLE_SID,dbca必须设置
 -r 数据库软件版本(112040)
```


###脚本使用demo
1.数据库软件安装，创建监听，创建数据库，数据库初步优化

```
#sh localinstall_linux_ora_v2.5.sh -d /oracle -o F -H zhjg -i 10.172.250.113 -r 112040 -O /oracle/oradata -a /oracle/arch -c zhs16gbk -n Y [-p 1523] -s hzwsdbhc  `
```
2.数据库软件安装，创建监听
```
#sh localinstall_linux_ora_v2.5.sh -d /oracle -o F -H zhjg -i 10.172.250.113 -r 112040 -O /oracle/oradata -a /oracle/arch -n Y [-p 1523]
```

3.数据库软件安装
```
#sh localinstall_linux_ora_v2.5.sh -d /oracle -o F -H zhjg -i 10.172.250.113 -r 112040 -O /oracle/oradata -a /oracle/arch
```
4.创建数据库，数据库初步优化
```
#sh localinstall_linux_ora_v2.5.sh -c zhs16gbk -d /oracle -O /oracle/oradata -a /oracle/arch -C Y -s hzwsdbhc  `
```
5.删除数据库和卸载数据库软件
```
#sh localinstall_linux_ora_v2.5.sh -d /oracle  -D Y
```

