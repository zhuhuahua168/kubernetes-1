##nfs说明###
###客户端：
    yum install nfs-utils

挂载：

    mount -t  nfs  服务端ip:服务端文件夹   客户端文件夹
例如：

    mount -t nfs 192.168.27.134:/mnt/nfs_file /nfsfile0
卸载：

    umount nfsfile0

常用命令：

1.查看是否安装nfs-utils,如果没有，则显示为空。
    
    ll /sbin/mount* 


###服务端:

     yum -y install nfs-utils 

 vi /etc/exports 

    /mnt/nfs_file *(rw,sync,no_root_squash,insecure)
或

    /mnt/nfs_file 192.168.27.0/24(rw,sync,no_root_squash,insecure)

启动：

    systemctl start rpcbind nfs-server
状态：

    systemctl status rpcbind nfs-server 

注：nfs-server状态可能是active(Exited)


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


 
