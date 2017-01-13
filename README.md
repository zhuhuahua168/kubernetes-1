##整体示意图
![image](https://github.com/zouhuigang/kubernetes/raw/master/images/master-node.png)
![image](https://github.com/zouhuigang/kubernetes/raw/master/images/service-pod.png)

1.构建DOCKER，生成docker images  [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/docker "查看构建DOCKER")


2.搭建NFS服务器，共享网站代码及数据库 [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/nfs-service)

3.搭建kubernetes环境 [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/zhg-study)

4.搭建flanneld网络环境 [查看详情](https://github.com/zouhuigang/kubernetes/tree/master/flannel)

5.kubernetes1.3版本[查看详情](https://github.com/zouhuigang/kubernetes/tree/master/kubernetes-update)


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

master中的config:

    KUBE_ALLOW_PRIV="--allow_privileged=true"


重启动服务：

    systemctl restart kubelet 
    systemctl restart kube-apiserver
 
 
查看设置：

    ps -ef | grep kube



在Kubernetes集群，pod访问其他pod的service，有两种方法。

一种是pod中添加环境变量，前提是service必须在pod之前创建；

一种是DNS自动发现。


##POD扩容
1.当我们测试的时候，用的pod和service。在不停止pod的情况下，创建rc来控制pod的扩容,rc中的replicas=2。

不然看不到效果
参照本项目的nginx-phpfpm-pod.yaml和nginx-phpfpm-rc.yaml

php测试代码：

    <?php
    $servername = "mysql";
    $username = "root";
    $password = "123456";
    echo $_SERVER['SERVER_ADDR'];
    // Create connection
     $conn = new mysqli($servername, $username, $password);

    // Check connection
    if ($conn->connect_error) {
    die("连接错误: " . $conn->connect_error);
    }
    echo "<h1>成功连接 MySQL 服务器</h1>";

    phpinfo();

    ?>

测试效果：
![image](https://github.com/zouhuigang/kubernetes/raw/master/images/pod1.png)
![image](https://github.com/zouhuigang/kubernetes/raw/master/images/pod2.png)

注意：2个ip地址不同，为pod的Cluster IP


### 增加服务器重启脚本,部署在/usr/local

server-restart.sh

开机启动:

vi /etc/rc.d/rc.local末尾中增加一行

sh /usr/local/server-restart.sh

  

##遇到的问题

Q:nfs挂载进mysql数据库,报错信息如下：

    [ERROR] --initialize specified but the data directory 
    has files in it. Aborting.
    
    [ERROR] Aborting

A： mysqld --initialize，如果 datadir 指向的目标目录下已经有数据文件，则会有类似提示。因此，需要先确保 datadir 目标目录下是空的，避免误操作破坏已有数据。所以mysqldata目录应该为空


Q:重启之后,kube-apiserver还是不能启动。the control process exited

A：查看/var/run/kubernetes中是否生成了证书文件。

 
