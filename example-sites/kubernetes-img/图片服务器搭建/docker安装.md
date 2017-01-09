
>使用go语言开发过图片处理服务，但是原生的image库的效率不理想，有些png、gif格式图片也不能正常处理。然后搜索解决办法时发现了nginx+lua+graphicmagick这一套解决方案，甚为满意，目前已应用到线上项目，运行稳定。
nginx做web服务器，对于需要缩放的图片交给lua脚本，lua脚本调用外部的graphicmagick程序来处理图片，然后将处理后的图片返回,由于直接调用graphicmagick所以可能实现各种强大的功能，加文字加水印都是很简单的了。

### 1.环境

    docker pull centos:7.3.1611


    docker run -it -d  centos:7.3.1611 /bin/bash

    docker exec -it 5b7 /bin/bash

初始化环境：

yum install wget
yum install -y gcc gcc-c++ zlib zlib-devel openssl openssl-devel pcre pcre-devel

###下载安装LuaJIT

        cd /usr/local/src
        wget http://luajit.org/download/LuaJIT-2.0.2.tar.gz
        tar -xzvf LuaJIT-2.0.2.tar.gz
        cd LuaJIT-2.0.2
        make
        make install


### 下载准备nginx lua模块

        cd /usr/local/src
        wget https://github.com/chaoslawful/lua-nginx-module/archive/v0.8.6.tar.gz
        tar -xzvf v0.8.6.tar.gz

解压之后目录变成了lua-nginx-module-0.8.6


### 安装nginx

        cd /usr/local/src/
        wget http://nginx.org/download/nginx-1.4.2.tar.gz
        tar -xzvf nginx-1.4.2.tar.gz
        cd nginx-1.4.2
        //先导入环境变量,告诉nginx去哪里找luajit
        export LUAJIT_LIB=/usr/local/lib
        export LUAJIT_INC=/usr/local/include/luajit-2.0
        ./configure --prefix=/usr/local/nginx-1.4.2 --add-module=../lua-nginx-module-0.8.6
        make -j2
        make install

会提示make[1]: Leaving directory `/usr/local/src/nginx-1.4.2'

以上是正常的!!!


1、验证nginx配置文件是否正确
方法一：进入nginx安装目录sbin下，输入命令
    ./nginx -t

看到如下显示

    nginx.conf syntax is ok

    nginx.conf test is successful

说明配置文件正确！

重启：

    进入nginx可执行目录sbin下，输入命令./nginx -s reload 即可

常见错误	

    # /usr/local/nginx-1.4.2/sbin/nginx -v
    /objs/nginx: error while loading shared libraries: libluajit-5.1.so.2:    cannot open shared object file: No such file or directory
解决方法：

    ln -s /usr/local/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2


### 安装graphicmagick

     yum install -y gcc libpng libjpeg libpng-devel libjpeg-devel ghostscript libtiff libtiff-devel freetype freetype-devel

     wget ftp://ftp.graphicsmagick.org/pub/GraphicsMagick/1.3/GraphicsMagick-1.3.22.tar.gz

    tar zxvf GraphicsMagick-1.3.22.tar.gz

     cd GraphicsMagick-1.3.22

     ./configure --prefix=/usr/local/graphicsmagick --enable-shared

     make && make install

之后出现提示
make[2]: Leaving directory `/usr/local/src/GraphicsMagick-1.3.22'
make[1]: Leaving directory `/usr/local/src/GraphicsMagick-1.3.22'

测试是否安装成功验证

    /usr/local/graphicsmagick/bin/gm version

如果提示：

bash: /usr/local/graphicsmagick/bin/gm: No such file or directory

这是由于安装graphicmagick时./configure --enable-shared未指定

    ./configure  --prefix=/usr/local/graphicsmagick --enable-shared

安装目录到/usr/local/graphicsmagick

已修复到上一步安装路径中


### 开始服务

docker中，由于docker已经启动了，只能用scp命令从另外一台本地linux虚拟机中拷贝文件了
安装scp命令
    cd /usr/local/nginx-1.4.2/
    yum install openssh-clients
    mkdir -p /usr/local/nginx-1.4.2/lua
    scp root@192.168.122.134:/usr/local/nginx-1.4.2/lua/img.lua  /usr/local/nginx-1.4.2/lua

复制nginx配置文件

scp root@192.168.122.134:/usr/local/nginx-1.4.2/conf/nginx.conf  /usr/local/nginx-1.4.2/conf/

输入密码：123456

复制2张测试图片

scp root@192.168.122.134:/opt/www/hdimage/*  /opt/www/hdimage/


###启动nginx服务

    cd /usr/local/nginx-1.4.2/sbin

     ./nginx 
    curl 127.0.0.1
    无报错,就说明成功


提交docker镜像

docker commit 5b7  registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.0


运行测试

docker run -d -it -p 8033:80 registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.0 /usr/local/nginx-1.4.2/sbin/nginx -g "daemon off;"

注意daemon off后面的分号

访问地址：
http://192.168.99.100:8033/1.jpg_100x100.jpg



### 制作自启动nginx docker镜像

    docker start 5b7 && docker exec -it 5b7 /bin/bash

vim start-imgserver.sh

    #!/bin/bash
	/usr/local/nginx-1.4.2/sbin/nginx 


测试： 

    curl 127.0.0.1  报错，则没启动nginx

提交docker镜像

    docker commit 5b7  registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.1

制作dockerfile文件

    FROM registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.1
    #启动
    #CMD  bash -C '/start-imgserver.sh';'bash'
	CMD "/start-imgserver.sh"
	#ENTRYPOINT /usr/local/nginx-1.4.2/sbin/nginx  -c /etc/nginx/nginx.conf && /bin/bash
	EXPOSE 80
	EXPOSE 443

构建dockerfile

docker build -t registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.2 .


运行

docker run -d -it -p 8033:80 registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.2

打开浏览器192.168.99.100:8033会看到404 not found image，部署成功

提交到阿里云

    docker push registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.2

### 在k8s中运行imgserver

>思路是，将imgserver的存储目录通过k8s和nfs挂载进php,java,go等出现目录下的uploads，这样各大程序就能共享了。上传图片就跟本地上传一样的思路，无需改变什么.

问题：

k8s中由于设置不了-d参数，所以只得修改sh的脚步，不然没法运行起来pod。
去掉-d参数

start-imgserver.sh脚本中添加

	#!/bin/bash
	/usr/local/nginx-1.4.2/sbin/nginx 
    # just keep this script running
    while [[ true ]]; do
	sleep 1
    done

然后运行：

    docker run  -it -p 8033:80 registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/imgserver:1.0.2


参考文献:

[http://www.open-open.com/lib/view/open1452400884823.html](http://www.open-open.com/lib/view/open1452400884823.html)

