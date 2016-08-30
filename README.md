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


 
