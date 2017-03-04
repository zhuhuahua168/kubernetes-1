### 环境说明

	k8s-master-www： 139.196.16.67(外网地址）
	        		 10.174.113.12(内网地址)
	
	k8s-master-qa: 139.196.48.36(外网地址）
	        	   10.174.155.169(内网地址)


### master

### 1.安装kubernetes

	systemctl disable firewalld
	systemctl stop firewalld
	yum -y install kubernetes etcd


	卸载旧版docker
	rpm -qa |grep docker
显示
	[root@k8s-master-www ~]# rpm -qa |grep docker
	docker-engine-selinux-1.11.2-1.el7.centos.noarch
	docker-engine-1.11.2-1.el7.centos.x86_64
	yum -y remove xxxx

### 2.设置ip host名称

	vi /etc/hosts
	[root@iZ1170t0g80Z ~]# cat /etc/hosts
	127.0.0.1 localhost
	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
	10.174.113.12 iZ1170t0g80Z
	10.174.155.169 k8s-master
	10.174.133.12 k8s-master-www
	
	[root@iZ1170t0g80Z ~]# 

### 3.修改主机名称

3.1查看主机状态：

    hostnamectl status
3.2修改

    hostnamectl --static set-hostname k8s-master-www
注意：你不必重启机器以激活永久主机名修改。上面的命令会立即修改内核主机名。注销并重新登入后在命令行提示来观察新的静态主机名。


### 4.生成证书文件，并复制到/var/run/kubernetes/

	[root@master ~]# openssl genrsa -out ca.key 2048

    [root@master ~]# openssl req -x509 -new -nodes -key ca.key -subj "/CN=master.k8s.com" -days 5000 -out ca.crt

    [root@master ~]# openssl genrsa -out server.key 2048
    [root@master ~]# cat /etc/hostname 
					 k8s-master-www

    [root@master ~]# openssl req -new -key server.key -subj "/CN=k8s-master-www" -out server.csr

    [root@master ~]# openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 5000
注意:

生成6个文件，ca.crt、ca.key、ca.srl、server.crt、server.csr、server.key复制至/var/run/kubernetes/，该目录已存在，无需创建.

    cp *.* /var/run/kubernetes/

在生成 server.csr 时 -subj 参数中 /CN 指定的名字需为 Master 的主机名。

另外，在生成 ca.crt 时 -subj 参数中 /CN 的名字最好与主机名不同，设为相同可能导致对普通 Master 的 HTTPS 访问认证失败。


### vim /etc/kubernetes/config:

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
    KUBE_MASTER="--master=http://k8s-master-www:8080"
    KUBE_ETCD_SERVERS="--etcd_servers=http://k8s-master-www:4001"


编辑vim /etc/kubernetes/apiserver:

	###
    # kubernetes system config
    #
    # The following values are used to configure the kube-apiserver
    #

    # The address on the local server to listen to.
    KUBE_API_ADDRESS="--insecure-bind-address=127.0.0.1"

    # The port on the local server to listen on.
    # KUBE_API_PORT="--port=8080"

    # Port minions listen on
    KUBELET_PORT="--kubelet-port=10250"

    # Comma separated list of nodes in the etcd cluster
    KUBE_ETCD_SERVERS="--etcd-servers=http://k8s-master-www:2379"

    # Address range to use for services
    KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

    # default admission control policies
    KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"

    # Add your own!
    KUBE_API_ARGS=""
    KUBE_API_ADDRESS="--address=0.0.0.0"
    KUBE_API_PORT="--port=8080"

其中再添加修改证书文件：

 KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

    KUBE_API_ARGS="--client-ca-file=/var/run/kubernetes/ca.crt \
               --tls-private-key-file=/var/run/kubernetes/server.key \
               --tls-cert-file=/var/run/kubernetes/server.crt"


vim controller-manager：

    KUBE_CONTROLLER_MANAGER_ARGS="--service-account-private-key-file=/var/run/kubernetes/server.key \
                              --root-ca-file=/var/run/kubernetes/ca.crt"

systemctl restart kube-controller-manager




node：

vim /etc/kubernetes/kubelet：

	###
    # kubernetes kubelet (minion) config

    # The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
    KUBELET_ADDRESS="--address=0.0.0.0"

    # The port for the info server to serve on
    KUBELET_PORT="--port=10250"

    # You may leave this blank to use the actual hostname
    KUBELET_HOSTNAME="--hostname-override=k8s-master-www"

    # location of the api-server
    KUBELET_API_SERVER="--api-servers=http://k8s-master-www:8080"

    # pod infrastructure container
    KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"

    # Add your own!
    KUBELET_ARGS=""


vim /etc/sysconfig/docker：

	INSECURE_REGISTRY='--insecure-registry gcr.io'


启动：

systemctl start etcd

systemctl start kube-apiserver

systemctl start kube-controller-manager 

systemctl start kube-scheduler


node:

    systemctl enable kube-proxy kubelet docker


    systemctl restart kube-proxy kubelet docker



安装面板：

	docker pull index.tenxcloud.com/google_containers/kubernetes-dashboard-amd64:v1.1.1

修改kube-dashboard/kube-dashboard-rc.yaml中的ip地址

	 - --apiserver-host=http://master-ip地址:8080
 


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites1_1\",
		  \"Name\": \"dev_group_sites1\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30001
		}" > /dev/null


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites2_1\",
		  \"Name\": \"dev_group_sites2\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 80
		}" > /dev/null

curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites3_1\",
		  \"Name\": \"dev_group_sites3\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30003
		}" > /dev/null


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites4_1\",
		  \"Name\": \"dev_group_sites4\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30005
		}" > /dev/null

curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites5_1\",
		  \"Name\": \"dev_group_sites5\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30006
		}" > /dev/null


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites6_1\",
		  \"Name\": \"dev_group_sites6\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30008
		}" > /dev/null


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites7_1\",
		  \"Name\": \"dev_group_sites7\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30010
		}" > /dev/null


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites8_1\",
		  \"Name\": \"dev_group_sites8\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30005
		}" > /dev/null


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites_startup_1\",
		  \"Name\": \"dev_group_sites_startup\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30012
		}" > /dev/null


curl -sf -X PUT "http://139.196.16.67:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites_zhongdongfei_1\",
		  \"Name\": \"dev_group_sites_zhongdongfei\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30014
		}" > /dev/null




 "dev_test-app:5000": {
        "ID": "dev_test-app:5000",
        "Service": "dev_test-app",
        "Tags": [],
        "Address": "139.196.16.67",
        "Port": 5000,
        "EnableTagOverride": false,
        "CreateIndex": 0,
        "ModifyIndex": 0
    }


consul-template -config /data/cfg/consul/tmpl.json > consul-template.out 2>&1 &

问题：

Q.如果kubectl get pods报错503 services等等，则可能是8080端口被占用了,因为haproxy用了一个8080端口，所以不能启动了。

A：修改haproxy模板以及配置文件的8080端口为8099

Q.[root@kubeMaster ~]# kubectl get pods
No resources found.

A:这个是因为没创建好pod

	kubectl describe svc kubernetes-dashboard --namespace=kube-system

	kubectl get deployment kubernetes-dashboard --namespace=kube-system
	kubectl get ns
	kubectl get ep
	kubectl cluster-info
	kubectl --namespace=kube-system get ep kubernetes-dashboard
	kubectl get pods --all-namespaces --show-all


文档：

http://blog.csdn.net/l1028386804/article/details/50779761

http://stackoverflow.com/questions/42097335/cant-access-kubernetes-dashboard








