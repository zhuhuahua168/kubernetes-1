##nfs说明###
centos7实践使用方法

server:

1.创建网站挂载目录

    mkdir -p /nfs_file/sites/51tywy

2.创建数据库挂载目录

    mkdir -p /nfs_file/mysqldata
注意：如果mysql为5.7要保存该目录没有任何数据

3.安装(server/client)

    yum -y install nfs-utils 

4.vi  /etc/exports

    /nfs_file/sites/51tywy *(rw,sync,no_root_squash,insecure)
    /nfs_file/mysqldata *(rw,sync,no_root_squash,insecure)

5.开启

    systemctl start rpcbind nfs-server

6.挂载

如采用kubernetes则，在pod.yaml中配置。其他挂载参考下面文档





##以下是通用介绍
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



Q:mount.nfs: access denied by server while mounting 139.196.16.67:/mnt/nfs_file/sites

A:

    cat /etc/exports
    exportfs -rv 
    查看挂载的目录是否有被共享出来
