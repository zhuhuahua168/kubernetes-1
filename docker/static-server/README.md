###静态文件服务器搭建,分理处css,images,js等

	docker pull index.tenxcloud.com/docker_library/nginx:latest


主要命令：

	docker run -it -d -p 8080:80  -v /mnt-linux/anooc_go/doc-img/:/usr/share/nginx/html index.tenxcloud.com/docker_library/nginx:latest


dockerfile文件
    FROM index.tenxcloud.com/docker_library/nginx
	COPY static-html-directory /usr/share/nginx/html

运行：
    docker run --name some-nginx -d -p 8080:80 index.tenxcloud.com/docker_library/nginx:latest


然后，可以通过浏览器根据地址访问到一个默认的网页，说明Nginx成功跑起来了。


#### 日志处理

Nginx有2个日志：

    access.log，记录每个HTTP请求信息
    error.log，记录Nginx运行中的错误，用于排错

运行如下命令：

    sudo docker run -it -d -p 8080:80  -v `pwd`/logs:/var/log/nginx index.tenxcloud.com/docker_library/nginx:latest

这个命令会在当前目录下创建logs目录，存放access.log和error.log。


### 设置静态网站路径

需要创建目录：

    config，目录下放一个文件，名为server，Nginx静态网站配置文件
    www，目录下放html文件，比如index.html

server文件：

    server {
        listen 80;

        root /www;
        index index.html index.htm;

        server_name localhost;
	}


运行文件
    sudo docker run -it -p 80:80 -v `pwd`/www:/www -v `pwd`/config:/etc/nginx/sites-enabled  -v `pwd`/logs:/var/log/nginx dockerfile/nginx


解释一下：

    -vpwd/www:/www，将当前路径下的www目录设置为/www，和server配置的路径对应
    -vpwd/config:/etc/nginx/sites-enabled，server文件的本地路径，映射到docker容器的nginx配置路径


其他：

    server {
    #侦听80端口
    listen       80;
    server_name  static.angrytoro.com;

    #设定本虚拟主机的访问日志
    access_log  /var/log/nginx/static.angrytoro.com.access.log  main;

    #静态文件，nginx自己处理
    location ~ ^/(images|javascript|js|css|flash|media|.*)/ {
        root /var/static;
        #过期30天，静态文件不怎么更新，过期可以设大一点，如果频繁更新，则可以设置得小一点。
        expires 30d;
    }
    }
