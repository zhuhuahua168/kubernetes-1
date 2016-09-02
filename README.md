###1.构建DOCKER，生成docker images  [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/docker "查看构建DOCKER")


###2.搭建NFS服务器，共享网站代码及数据库 [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/nfs-service)

###3.搭建kubernetes环境 [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/zhg-study)


##kubernetes-nginx-php-mysql搭建说明###

###nginx-phpfpm-pod.yaml说明:####

    volumeMounts:
      - name: nfs 
        mountPath: "/usr/share/nginx/html"//容器中的目录

    volumes://定义挂载的nfs服务器
      - name: nfs
      nfs:
        server: 192.168.27.134 //服务器地址
        path: "/mnt/nfs_file" //服务器的共享目录
注：node节点需安装nfs客户端,搭建详细见nfs说明


###注意：nfs给pod挂载文件时，不能挂载配置文件，否则不能解析。如不能把nginx的default.cnf挂载上docker容器内的nginx,配置文件尽可能做成镜像


 
