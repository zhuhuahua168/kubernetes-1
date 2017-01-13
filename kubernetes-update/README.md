## node节点


#### node基础镜像下载



	docker pull index.tenxcloud.com/google_containers/pause:2.0

	docker tag index.tenxcloud.com/google_containers/pause:2.0 gcr.io/google_containers/pause:2.0

#### 安装kubernetes 

	systemctl disable firewalld
	systemctl stop firewalld
	yum -y install kubernetes etcd
	
#### 增加host名字：

	[root@k8s-node1 ~]# cat /etc/hosts
	127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
	192.168.122.135  k8s-master
	192.168.122.136  k8s-node1

增加master和所有node的ip解析：

<font color=#0099ff size=4 face="黑体">192.168.122.135  k8s-master</font>

<font color=#0099ff size=4 face="黑体">192.168.122.136  k8s-node1</font>


#### 修改config配置文件vim /etc/kubernetes/config：

	[root@k8s-node2 ~]# cat /etc/kubernetes/config
	###
	# kubernetes system config
	#
	# The following values are used to configure various aspects of all
	# kubernetes services, including
	#
	#   kube-apiserver.service
	#   kube-controller-manager.service
	#   kube-scheduler.service
	#   kubelet.service
	#   kube-proxy.service
	# logging to stderr means we get it in the systemd journal
	KUBE_LOGTOSTDERR="--logtostderr=true"
	
	# journal message level, 0 is debug
	KUBE_LOG_LEVEL="--v=0"
	
	# Should this cluster be allowed to run privileged docker containers
	KUBE_ALLOW_PRIV="--allow-privileged=false"
	
	# How the controller-manager, scheduler, and proxy find the apiserver
	KUBE_MASTER="--master=http://k8s-master:8080"
	KUBE_ETCD_SERVERS="--etcd_servers=http://k8s-master:4001"
	[root@k8s-node2 ~]# 

修改为：
<font color=#0099ff size=4 face="黑体">

	KUBE_MASTER="--master=http://k8s-master:8080"
	KUBE_ETCD_SERVERS="--etcd_servers=http://k8s-master:4001"

</font>


#### 修改配置文件vim /etc/kubernetes/kubelet：


	[root@k8s-node2 ~]# cat /etc/kubernetes/kubelet
	###
	# kubernetes kubelet (minion) config
	
	# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
	KUBELET_ADDRESS="--address=0.0.0.0"
	
	# The port for the info server to serve on
	KUBELET_PORT="--port=10250"
	
	# You may leave this blank to use the actual hostname
	KUBELET_HOSTNAME="--hostname-override=k8s-node2"
	
	# location of the api-server
	KUBELET_API_SERVER="--api-servers=http://k8s-master:8080"
	
	# pod infrastructure container
	KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"
	
	# Add your own!
	KUBELET_ARGS=""
	
	[root@k8s-node2 ~]# 

修改为：
<font color=#0099ff size=4 face="黑体">

	KUBELET_ADDRESS="--address=0.0.0.0"
	KUBELET_HOSTNAME="--hostname-override=k8s-node2" 本机名称
	KUBELET_API_SERVER="--api-servers=http://k8s-master:8080"

</font>


#### 修改docker,vim /etc/sysconfig/docker

	[root@k8s-node1 ~]# cat /etc/sysconfig/docker
	# /etc/sysconfig/docker
	
	# Modify these options if you want to change the way the docker daemon runs
	OPTIONS='--selinux-enabled --log-driver=journald'
	if [ -z "${DOCKER_CERT_PATH}" ]; then
	    DOCKER_CERT_PATH=/etc/docker
	fi
	
	# If you want to add your own registry to be used for docker search and docker
	# pull use the ADD_REGISTRY option to list a set of registries, each prepended
	# with --add-registry flag. The first registry added will be the first registry
	# searched.
	#ADD_REGISTRY='--add-registry registry.access.redhat.com'
	
	# If you want to block registries from being used, uncomment the BLOCK_REGISTRY
	# option and give it a set of registries, each prepended with --block-registry
	# flag. For example adding docker.io will stop users from downloading images
	# from docker.io
	# BLOCK_REGISTRY='--block-registry'
	
	# If you have a registry secured with https but do not have proper certs
	# distributed, you can tell docker to not look for full authorization by
	# adding the registry to the INSECURE_REGISTRY line and uncommenting it.
	INSECURE_REGISTRY='--insecure-registry gcr.io'
	
	# On an SELinux system, if you remove the --selinux-enabled option, you
	# also need to turn on the docker_transition_unconfined boolean.
	# setsebool -P docker_transition_unconfined 1
	
	# Location used for temporary files, such as those created by
	# docker load and build operations. Default is /var/lib/docker/tmp
	# Can be overriden by setting the following environment variable.
	# DOCKER_TMPDIR=/var/tmp
	
	# Controls the /etc/cron.daily/docker-logrotate cron job status.
	# To disable, uncomment the line below.
	# LOGROTATE=false
	#
	
	# docker-latest daemon can be used by starting the docker-latest unitfile.
	# To use docker-latest client, uncomment below line
	#DOCKERBINARY=/usr/bin/docker-latest
	[root@k8s-node1 ~]# 

修改为：
<font color=#0099ff size=4 face="黑体">

	INSECURE_REGISTRY='--insecure-registry gcr.io'

</font>

### 启动node节点
	
	#开机启动
	systemctl enable kube-proxy kubelet docker
	#重新启动
	systemctl restart kube-proxy kubelet docker


## flannel搭建



#### flannel的配置信息

	[root@k8s-node2 ~]# cat /etc/sysconfig/flanneld
	# Flanneld configuration options  
	
	# etcd url location.  Point this to the server where etcd runs
	FLANNEL_ETCD_ENDPOINTS="http://k8s-master:2379"
	
	# etcd config key.  This is the configuration key that flannel queries
	# For address range assignment
	FLANNEL_ETCD_PREFIX="/coreos.com/network"
	
	# Any additional options that you want to pass
	#FLANNEL_OPTIONS=""
	 
	[root@k8s-node2 ~]# 


#### flannel的版本

	[root@k8s-node2 ~]# flanneld --version
	0.5.5
	[root@k8s-node2 ~]# 


#### 环境ip

	k8s-master:192.168.122.135
	k8s-node1:192.168.122.136
	k8s-node2:192.168.122.137

#### 测试master中etcd是否成功

	[root@k8s-node1 ~]# curl -L http://192.168.122.135:2379/v2/keys/coreos.com/network/config
	{"action":"get","node":{"key":"/coreos.com/network/config","value":"{\"Network\":\"10.254.0.0/16\"}","modifiedIndex":1489,"createdIndex":1489}}
	[root@k8s-node1 ~]# 


#### 启动flanneld

	[root@k8s-node2 ~]# systemctl restart flanneld
	[root@k8s-node2 ~]# systemctl restart docker

	systemctl enable kube-proxy kubelet docker

	systemctl restart kube-proxy kubelet docker



#### 问题

A:Failed to retrieve network config: client: etcd cluster is unavailable or misconfigured

Q:在node节点上部署flanneld，出现这个问题，搞了很久。发现原来是master节点的etcd没有搞好。重启动下etcd就好了

	node:

	# 测试能否访问master节点中的etcd

	curl -v 192.168.122.135:2379

	如不能访问会出现：curl: (7) Failed connect to 192.168.122.136:2379; Connection refused
	
	下面是访问成功的回馈信息:
	[root@k8s-node2 ~]# curl -v 192.168.122.135:2379
	* About to connect() to 192.168.122.135 port 2379 (#0)
	*   Trying 192.168.122.135...
	* Connected to 192.168.122.135 (192.168.122.135) port 2379 (#0)
	> GET / HTTP/1.1
	> User-Agent: curl/7.29.0
	> Host: 192.168.122.135:2379
	> Accept: */*
	> 
	< HTTP/1.1 404 Not Found
	< Content-Type: text/plain; charset=utf-8
	< X-Content-Type-Options: nosniff
	< Date: Thu, 12 Jan 2017 16:56:22 GMT
	< Content-Length: 19
	< 
	404 page not found
	* Connection #0 to host 192.168.122.135 left intact

A:定位“kubernetes pod卡在ContainerCreating状态”问题的方法

Q:kubernetes1.2.x版本需要pause:0.8版本的,kubernetes1.3.x版本需要pause:2.0版本的。不然一直下不下来镜像

    docker pull index.tenxcloud.com/google_containers/pause:2.0

	docker tag index.tenxcloud.com/google_containers/pause:2.0 gcr.io/google_containers/pause:2.0
