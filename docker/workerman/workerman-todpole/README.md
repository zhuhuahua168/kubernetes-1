workerman-todpole
=================

蝌蚪游泳交互程序 使用PHP（workerman框架）+HTML5开发

[线上DEMO](http://kedou.workerman.net)

在自己的服务器上(云主机、vps、物理主机等)安装部署
==================

## Linux 系统

1、下载或者clone代码到本地 详细安装教程见 [www.workerman.net/workerman-todpole](http://www.workerman.net/workerman-todpole)

2、进入目录运行 php start.php start -d

3、浏览器访问地址  http://ip:8383 （ip为服务器ip）如图：（如果无法打开页面请尝试关闭服务器防火墙）

![小蝌蚪游戏截图](https://github.com/walkor/workerman-todpole/blob/master/Applications/Todpole/Web/images/workerman-todpole-browser.png?raw=true)

## Windows系统
（windows系统仅作为开发测试环境）   
首先windows系统需要先下载windows版本workerman，替换Workerman目录。

步骤：  
1、下载代码到本地,从源码中找到Workerman目录并删除  
2、下载windows版本workerman，zip地址 https://github.com/walkor/workerman-for-win/archive/master.zip  
3、解压到原Worekrman目录所在位置，同时将目录workerman-for-win-master重命名为Workerman(注意第一个字母W为大写)  
4、双击start_for_win.bat启动（系统已经装好php，并设置好环境变量，要求版本php>=5.3.3）  
5、浏览器访问地址  http://127.0.0.1:8383   

注意：windows系统下无法使用 stop reload status 等命令

虚拟空间（静态空间、php、jsp、asp等）安装部署
==================
虚拟空间安装请使用这个包 [网页空间版本](https://github.com/walkor/workerman-todpole-web)


#启动
php start.php start -d  #持久启动

php start.php start  #调试打印客服端发来的信息

php start.php status #查看状态

php start.php stop #停止

#问题
如果能Ping通，不能发生消息到db中，则升级http://workerman.net/gatewaydoc/appendices/mysql.html
apt-get install php5-mysql
重启动聊天

#DB链接问题
Q:exception 'PDOException' with message 'SQLSTATE[HY000] [2003] Can't connect to MySQL server on '139.196.16.67' 

A:
workerman-todpole\Applications\Todpole\Config\Db.php
   
`    <?php
namespace Config;
/**
 * mysql配置
 * @author walkor
 */
class Db
{
	public static $skiper = array(
        'host'    => 'mysql',
        'port'    => 3306,
        'user'    => 'root',
        'password' => 'TYwy2016720',
        'dbname'  => 'skiper',
        'charset'    => 'utf8',
    );
}` 

host中的mysql是docker-compose中定义的，如果用host填写的是宿主机的ip，则会报出这个错误。





