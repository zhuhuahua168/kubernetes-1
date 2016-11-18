### windows下构建聊天服务器

首先进入workerman\workerman-todpole\Applications\Todpole\Config下找到DB.php，修改聊天服务器db地址和密码

由于数据库用户和密码的修改，可能要构建多次镜像

1.进入当前目录

    cd /d/www/github/kubernetes/docker/workerman


2.构建镜像


    docker build -t registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/workerman:v1.0.1 .

不使用缓存

    docker build --no-cache=true -t registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/workerman:v1.0.1 .

3.推送到阿里云


	docker push registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/workerman:v1.0.1


测试下：

    docker run -it  registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/workerman:v1.0.1 /bin/bash


注意： ADD拷贝当前目录到docker linux中的/目录下面