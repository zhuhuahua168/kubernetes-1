新增nfs

vi /etc/exports :


    /nfs_file/sites/51tywy *(rw,sync,no_root_squash,insecure)
    /nfs_file/mysqldata *(rw,sync,no_root_squash,insecure)
    /nfs_file/sites/yyang *(rw,sync,no_root_squash,insecure)
    /nfs_file/sites/anooc *(rw,sync,no_root_squash,insecure)
    /nfs_file/sites/sys *(rw,sync,no_root_squash,insecure)

查看刷新：

    exportfs -rv

### 挂载图片服务器的目录到网站根目录下的uploads/

