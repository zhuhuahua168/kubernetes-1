###镜像下载

	[root@k8s-master ~]# kubectl version
	Client Version: version.Info{Major:"1", Minor:"5", GitVersion:"v1.5.2", GitCommit:"269f928217957e7126dc87e6adfa82242bfe5b1e", GitTreeState:"clean", BuildDate:"2017-07-03T15:31:10Z", GoVersion:"go1.7.4", Compiler:"gc", Platform:"linux/amd64"}
	Server Version: version.Info{Major:"1", Minor:"5", GitVersion:"v1.5.2", GitCommit:"269f928217957e7126dc87e6adfa82242bfe5b1e", GitTreeState:"clean", BuildDate:"2017-07-03T15:31:10Z", GoVersion:"go1.7.4", Compiler:"gc", Platform:"linux/amd64"}
	[root@k8s-master ~]# 



	docker tag perconalab/proxysql registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/proxysql:latest

	docker push registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/proxysql:latest

下载镜像：

	docker pull registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/proxysql:latest

	docker tag registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/proxysql perconalab/proxysql

	docker pull registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/percona-xtradb-cluster:5.6test

	docker tag registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/percona-xtradb-cluster:5.6test perconalab/percona-xtradb-cluster:5.6test


创建：

	kubectl create -f pxc.yaml


yaml:

https://codebeautify.org/yaml-to-json-xml-csv


增加:

	kubectl exec -it proxysql-rc-3bdv9 add_cluster_nodes.sh

镜像密码，进入容器：

	mysql -h 127.0.0.1 -P6032 -uadmin -padmin


日志：

	[root@k8s-master ~]# kubectl exec -it proxysql-rc-2j019  add_cluster_nodes.sh
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100   113  100   113    0     0  56135      0 --:--:-- --:--:-- --:--:--  110k
	mysql: [Warning] Using a password on the command line interface can be insecure.
	mysql: [Warning] Using a password on the command line interface can be insecure.
	[root@k8s-master ~]# 


描述：

	 kubectl describe -f pxc-srv.yaml 

连接：

	 mysql -h 127.0.0.1 -uroot -p  -P30001
	  Theistareyk

查看状态：
	
	mysql> status
	--------------
	mysql  Ver 14.14 Distrib 5.6.29-76.2, for Linux (x86_64) using  6.2
	
	Connection id:          1479
	Current database:
	Current user:           root@127.0.0.1
	SSL:                    Not in use
	Current pager:          stdout
	Using outfile:          ''
	Using delimiter:        ;
	Server version:         5.6.29-76.2-56 Percona XtraDB Cluster (GPL), Release rel76.2, Revision b60e98d, WSREP version 25.15, wsrep_25.15
	Protocol version:       10
	Connection:             127.0.0.1 via TCP/IP
	Server characterset:    latin1
	Db     characterset:    latin1
	Client characterset:    latin1
	Conn.  characterset:    latin1
	TCP port:               3306
	Uptime:                 1 hour 54 min 27 sec
	
	Threads: 5  Questions: 4666  Slow queries: 0  Opens: 87  Flush tables: 1  Open tables: 80  Queries per second avg: 0.679
	--------------
	
	mysql> 


扩容：

	kubectl scale --replicas=6 -f pxc-rc.yaml



其中：

	DISCOVERY_SERVICE：为etcd服务，用于服务发现等


注意问题：

	services.yaml添加nodePort的时候，需要指定一个类型,type:

	如：  type: NodePort



### etc得到所有的key值

	 curl -L http://192.168.122.142:2379/v2/keys

### 查看集群队列

	curl -L http://192.168.122.142:2379/v2/keys/pxc-cluster




### navicat连接信息

	ip地址：192.168.122.142 端口：30001

	用户名：proxyuser 密码：s3cret



[https://stackoverflow.com/questions/44110876/kubernetes-service-external-ip-pending](https://stackoverflow.com/questions/44110876/kubernetes-service-external-ip-pending)