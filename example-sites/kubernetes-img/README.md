### 图片文件静态服务器

### 配置nfs共享目录

	cat /etc/exports
#### www服务器添加 

    systemctl stop nfs-server

    vi /etc/exports
    /nfs_file/img *(rw,sync,no_root_squash,insecure)

	systemctl start nfs-server

#### 域名指向

    
    img.xxx.com在haproxy中配置
    启动命令
    systemctl start haproxy
    停止命令
    systemctl stop haproxy




