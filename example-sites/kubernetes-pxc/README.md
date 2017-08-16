
### 环境说明：

ui访问集群：

	http://192.168.122.142:8080/ui

pxc.yaml里面的地址：

	k8s的etcd存储地址：192.168.122.142:2379


创建宿主机存储：

	mkdir -p /mnt2/mysql-data
### 使用

创建：

	kubectl create -f pxc.yaml

将3个mysql注入proxysql中

	kubectl exec -it proxysql-rc-4e936 add_cluster_nodes.sh

之后才可通过navicat连接mysql:

	ip地址：192.168.122.142 端口：30001

	用户名：proxyuser 密码：s3cret


扩容：

	#kubectl scale --replicas=3 -f pxc.yaml
	
	#kubectl scale rc proxysql-rc --replicas=3 

	kubectl scale rc pxc-app --replicas=3 #奇数



问题：

Q1:chown: changing ownership of ‘/var/lib/mysql/....‘: Permission denied：

A1：

    在docker run中加入 --privileged=true  给容器加上特定权限
    关闭selinux，临时（setenforce 0） 

	永久关闭:
	vi /etc/selinux/config	
	将SELINUX=enforcing改为SELINUX=disabled
	设置后需要重启才能生效

    在selinux添加规则，修改挂载目录de

[https://www.percona.com/blog/2016/06/16/scaling-percona-xtradb-cluster-with-proxysql-in-kubernetes/](https://www.percona.com/blog/2016/06/16/scaling-percona-xtradb-cluster-with-proxysql-in-kubernetes/)