#workerman 聊天服务器的镜像
FROM registry.aliyuncs.com/acs-sample/ubuntu:14.04

#拷贝执行脚本到容器根目录中
ADD start.sh /
ADD workerman-todpole/ /workerman-todpole/
#配置环境
RUN apt-get update \
	&&apt-get -y  install php5-cli git gcc php-pear php5-dev libevent-dev  \
	&&pecl install channel://pecl.php.net/libevent-0.1.0  \
	&&echo extension=libevent.so > /etc/php5/cli/conf.d/libevent.ini \
	#安装mysql数据库依赖
	&&apt-get -y install php5-mysql \
	&&git clone https://github.com/walkor/Workerman  \	
	#添加sh执行权限
	&&chmod a+x /start.sh

#启动workerman
CMD  bash -C '/start.sh';'bash'
#CMD ["/start.sh"]

EXPOSE 8383
EXPOSE 3232
