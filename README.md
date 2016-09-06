1.构建DOCKER，生成docker images  [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/docker "查看构建DOCKER")


2.搭建NFS服务器，共享网站代码及数据库 [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/nfs-service)

3.搭建kubernetes环境 [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/zhg-study)


###kubernetes-nginx-php-mysql搭建说明###

pod挂载nfs

    volumeMounts:
      - name: nfs 
        mountPath: "/usr/share/nginx/html"//容器中的目录

pod定义nfs

    volumes://定义挂载的nfs服务器
      - name: nfs
        nfs:
          server: 192.168.27.134 //服务器地址
          path: "/mnt/nfs_file" //服务器的共享目录

注：node节点需安装nfs客户端,搭建详细见nfs说明


注意：nfs给pod挂载文件时，不能挂载配置文件，否则不能解析。如不能把nginx的default.cnf挂载上docker容器内的nginx,配置文件尽可能做成镜像

##使用securityContext
master中的kubelet:

    KUBELET_OPTS="--allow_privileged=true"

master中的api-service:

    KUBE_APISERVER_OPTS="--allow_privileged=true"


重启动服务：

    systemctl restart kubelet 
    systemctl restart kube-apiserver
 
 
查看设置：

    ps -ef | grep kube



在Kubernetes集群，pod访问其他pod的service，有两种方法。

一种是pod中添加环境变量，前提是service必须在pod之前创建；

一种是DNS自动发现。


##遇到的问题

Q:nfs挂载进mysql数据库,报错信息如下：

    [ERROR] --initialize specified but the data directory 
    has files in it. Aborting.
    
    [ERROR] Aborting

A： mysqld --initialize，如果 datadir 指向的目标目录下已经有数据文件，则会有类似提示。因此，需要先确保 datadir 目标目录下是空的，避免误操作破坏已有数据。所以mysqldata目录应该为空

 
