### 手动在CentOS7.2上部署kubernetes1.8.4集群

环境：

	在VMware Workstation Pro，新建一个centos7.2的镜像

	ip:192.168.122.148


### 证书创建及初始化环境

cfs软件安装:

	mkdir -p /home/ssl && cd /home/ssl

	wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
	wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
	wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

	#三个软件可以在这下载,然后上传到/home/ssl,链接：http://pan.baidu.com/s/1nuAYZ5v 密码：tv4n

	cd /home/ssl && chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64

	mkdir -p /root/local/bin

	sudo mv cfssl_linux-amd64 /root/local/bin/cfssl
	sudo mv cfssljson_linux-amd64 /root/local/bin/cfssljson
	sudo mv cfssl-certinfo_linux-amd64 /root/local/bin/cfssl-certinfo
	export PATH=/root/local/bin:$PATH


证书生成:

	sudo mkdir -p /root/ssl && cd /root/ssl

	cfssl print-defaults config > config.json
	cfssl print-defaults csr > csr.json

	将配置文件中的ca-config.json和ca-csr.json上传到/root/ssl
	cfssl gencert -initca ca-csr.json | cfssljson -bare ca
	
	ls ca*
	ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem


cat kubernetes-csr.json:

	{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "192.168.122.148",
      "10.254.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
	}

如果 hosts 字段不为空则需要指定授权使用该证书的 IP 或域名列表，由于该证书后续被 etcd 集群和 kubernetes master 集群使用，所以上面分别指定了 etcd 集群、kubernetes master 集群的主机 IP 和 kubernetes 服务的服务 IP（一般是 kue-apiserver 指定的 service-cluster-ip-range 网段的第一个IP，如 10.254.0.1。


再生成证书:

	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

得到:

	ls kubernetes*
	kubernetes.csr  kubernetes-csr.json  kubernetes-key.pem  kubernetes.pem


cat admin-csr.json:

	{
	  "CN": "admin",
	  "hosts": [],
	  "key": {
	    "algo": "rsa",
	    "size": 2048
	  },
	  "names": [
	    {
	      "C": "CN",
	      "ST": "BeiJing",
	      "L": "BeiJing",
	      "O": "system:masters",
	      "OU": "System"
	    }
	  ]
	}

生成admin证书:

	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

得到:

	ls admin*
	admin.csr  admin-csr.json  admin-key.pem  admin.pem


cat kube-proxy-csr.json:

	{
	  "CN": "system:kube-proxy",
	  "hosts": [],
	  "key": {
	    "algo": "rsa",
	    "size": 2048
	  },
	  "names": [
	    {
	      "C": "CN",
	      "ST": "BeiJing",
	      "L": "BeiJing",
	      "O": "k8s",
	      "OU": "System"
	    }
	  ]
	}

生成 kube-proxy 客户端证书和私钥:

	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy

得到:

	ls kube-proxy*
	kube-proxy.csr  kube-proxy-csr.json  kube-proxy-key.pem  kube-proxy.pem


生成的文件如下:

    ca-key.pem
    ca.pem
    kubernetes-key.pem
    kubernetes.pem
    kube-proxy.pem
    kube-proxy-key.pem
    admin.pem
    admin-key.pem


校验证书是否正确:

	openssl x509  -noout -text -in  kubernetes.pem
	或
	cfssl-certinfo -cert kubernetes.pem

确认 Issuer 字段的内容和 ca-csr.json 一致；

确认 Subject 字段的内容和 kubernetes-csr.json 一致；

确认 X509v3 Subject Alternative Name 字段的内容和 kubernetes-csr.json 一致；

确认 X509v3 Key Usage、Extended Key Usage 字段的内容和 ca-config.json 中 kubernetes profile 一致


### 分发证书:


将生成的证书和秘钥文件（后缀名为.pem）拷贝到所有机器的 /etc/kubernetes/ssl 目录下备用；
	
	$ sudo mkdir -p /etc/kubernetes/ssl
	$ sudo cp *.pem /etc/kubernetes/ssl

查看:

	ls /etc/kubernetes/ssl
	admin-key.pem  admin.pem  ca-key.pem  ca.pem  kube-proxy-key.pem  kube-proxy.pem  kubernetes-key.pem  kubernetes.pem



### 安装etcd

	yum install -y etcd

vi /etc/etcd/etcd.conf

	ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
	ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"

启动:
	systemctl enable etcd
	systemctl start etcd


在任一 kubernetes master 机器上执行如下命令，验证：

	etcdctl \
	  --ca-file=/etc/kubernetes/ssl/ca.pem \
	  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
	  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	  cluster-health


显示:

	member 8e9e05c52164694d is healthy: got healthy result from http://0.0.0.0:2379
	cluster is healthy
	


设置网络：

	etcdctl  set /coreos.com/network/config '{"Network":"10.254.0.0/16"}'


### etcd(https访问版本)

vi /usr/lib/systemd/system/etcd.service 

添加证书文件进去：

	[Unit]
	Description=Etcd Server
	After=network.target
	After=network-online.target
	Wants=network-online.target
	Documentation=https://github.com/coreos
	
	[Service]
	Type=notify
	WorkingDirectory=/var/lib/etcd/
	EnvironmentFile=-/etc/etcd/etcd.conf
	ExecStart=/usr/bin/etcd \
	  --name ${ETCD_NAME} \
	  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
	  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	  --peer-cert-file=/etc/kubernetes/ssl/kubernetes.pem \
	  --peer-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	  --trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
	  --peer-trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
	  --initial-advertise-peer-urls ${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
	  --listen-peer-urls ${ETCD_LISTEN_PEER_URLS} \
	  --listen-client-urls ${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
	  --advertise-client-urls ${ETCD_ADVERTISE_CLIENT_URLS} \
	  --initial-cluster-token ${ETCD_INITIAL_CLUSTER_TOKEN} \
	  --initial-cluster infra1=https://192.168.122.148:2380 \
	  --initial-cluster-state new \
	  --data-dir=${ETCD_DATA_DIR}
	Restart=on-failure
	RestartSec=5
	LimitNOFILE=65536
	
	[Install]
	WantedBy=multi-user.target


指定 etcd 的工作目录为 /var/lib/etcd，数据目录为 /var/lib/etcd，需在启动服务前创建这两个目录；

为了保证通信安全，需要指定 etcd 的公私钥(cert-file和key-file)、Peers 通信的公私钥和 CA 证书(peer-cert-file、peer-key-file、peer-trusted-ca-file)、客户端的CA证书（trusted-ca-file）；

创建 kubernetes.pem 证书时使用的 kubernetes-csr.json 文件的 hosts 字段包含所有 etcd 节点的IP，否则证书校验会出错；

--initial-cluster-state 值为 new 时，--name 的参数值必须位于 --initial-cluster 列表中


vi /etc/etcd/etcd.conf

	# [member]
	ETCD_NAME=infra1
	ETCD_DATA_DIR="/var/lib/etcd"
	ETCD_LISTEN_PEER_URLS="https://192.168.122.148:2380"
	ETCD_LISTEN_CLIENT_URLS="https://192.168.122.148:2379"
	
	#[cluster]
	ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.122.148:2380"
	ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
	ETCD_ADVERTISE_CLIENT_URLS="https://192.168.122.148:2379"


启动:

	systemctl daemon-reload
	systemctl restart etcd

验证:

	[root@localhost system]# etcdctl \
	>   --ca-file=/etc/kubernetes/ssl/ca.pem \
	>   --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
	>   --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	>   cluster-health
	member b600dc636d7091e0 is healthy: got healthy result from https://192.168.122.148:2379
	cluster is healthy
	[root@localhost system]# 


### 安装docker和flannel 

 	yum install -y docker flannel 

vi /etc/sysconfig/flanneld：

	FLANNEL_ETCD="http://192.168.122.148:2379"  #http://k8s-master:2379"
	FLANNEL_ETCD_KEY="/coreos.com/network"

启动:

	systemctl stop docker

	systemctl start flanneld
	systemctl start docker
	

	



### 创建kubeconfig 文件

>kubernetes 1.4 开始支持由 kube-apiserver 为客户端生成 TLS 证书的 TLS Bootstrapping 功能，这样就不需要为每个客户端生成证书了；该功能当前仅支持为 kubelet 生成证书

Token可以是任意的包涵128 bit的字符串，可以使用安全的随机数发生器生成:

	cd /etc/kubernetes/

	export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
	cat > token.csv <<EOF
	${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
	EOF

将生成token.cvs

    更新 token.csv 文件，分发到所有机器 (master 和 node）的 /etc/kubernetes/ 目录下，分发到node节点上非必需；
    重新生成 bootstrap.kubeconfig 文件，分发到所有 node 机器的 /etc/kubernetes/ 目录下；
    重启 kube-apiserver 和 kubelet 进程；
    重新 approve kubelet 的 csr 请求；



##### bootstrap.kubeconfig：

	cd /etc/kubernetes

	export KUBE_APISERVER="https://192.168.122.148:6443"

	kubectl config set-cluster kubernetes \
	  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
	  --embed-certs=true \
	  --server=${KUBE_APISERVER} \
	  --kubeconfig=bootstrap.kubeconfig

设置客户端认证参数

	kubectl config set-credentials kubelet-bootstrap \
	  --token=${BOOTSTRAP_TOKEN} \
	  --kubeconfig=bootstrap.kubeconfig


设置上下文参数

	kubectl config set-context default \
	  --cluster=kubernetes \
	  --user=kubelet-bootstrap \
	  --kubeconfig=bootstrap.kubeconfig


设置默认上下文

	kubectl config use-context default --kubeconfig=bootstrap.kubeconfig


##### kube-proxy.kubeconfig：

	export KUBE_APISERVER="https://192.168.122.148:6443"

	 kubectl config set-cluster kubernetes \
  		--certificate-authority=/etc/kubernetes/ssl/ca.pem \
  		--embed-certs=true \
  		--server=${KUBE_APISERVER} \
  		--kubeconfig=kube-proxy.kubeconfig

设置客户端认证参数

	kubectl config set-credentials kube-proxy \
	  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
	  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
	  --embed-certs=true \
	  --kubeconfig=kube-proxy.kubeconfig

设置上下文参数

	kubectl config set-context default \
	  --cluster=kubernetes \
	  --user=kube-proxy \
	  --kubeconfig=kube-proxy.kubeconfig

设置默认上下文

	kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

##### 分发 kubeconfig 文件

将两个 kubeconfig 文件分发到所有 Node 机器的 /etc/kubernetes/ 目录

	cp bootstrap.kubeconfig kube-proxy.kubeconfig /etc/kubernetes/


### github下载


##### 下载地址:	[github kubernetes releases 页面](https://github.com/kubernetes/kubernetes/releases)

	mkdir -p /home/kubernetes && cd /home/kubernetes 
	yum install -y wget
	wget https://github.com/kubernetes/kubernetes/releases/download/v1.8.4/kubernetes.tar.gz

	# 如果网不好，可以在这里下载,版本是v1.8.4,大小3.94M
	# 链接：http://pan.baidu.com/s/1i5IiP0L 密码：0zc4

	tar -xzvf kubernetes.tar.gz

	cd /home/kubernetes/kubernetes

	./cluster/get-kube-binaries.sh

	选择y之后，开始下载...

完成：

	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
	100   161  100   161    0     0    133      0  0:00:01  0:00:01 --:--:--   134
	100 24.9M  100 24.9M    0     0  9080k      0  0:00:02  0:00:02 --:--:-- 15.6M

	md5sum(kubernetes-client-linux-amd64.tar.gz)=f557c69123941e07525c6f0cae734f0e
	sha1sum(kubernetes-client-linux-amd64.tar.gz)=e6b2fdf04b978037360f2a0f403d639aca7857aa
	
	Extracting /root/kubernetes/client/kubernetes-client-linux-amd64.tar.gz into /root/kubernetes/platforms/linux/amd64
	Add '/root/kubernetes/client/bin' to your PATH to use newly-installed binaries.
	[root@k8s-master1 kubernetes]# 

下载的文件有:

	kubernetes-server-linux-amd64.tar.gz
	kubernetes-client-linux-amd64.tar.gz

注:

>如果下载完成，这一步可忽略。
>也可以直接在github的[CHANGELOG页面](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md)下载这2个文件:
>
>wget https://dl.k8s.io/v1.8.4/kubernetes-server-linux-amd64.tar.gz
>##### 链接：http://pan.baidu.com/s/1hr3H3YO 密码：889l，上传到/home/kubernetes/kubernetes
>tar -xzvf kubernetes-server-linux-amd64.tar.gz
>
>cd kubernetes
>
>tar -xzvf  kubernetes-src.tar.gz

>cd kubernetes #实际路径/home/kubernetes/kubernetes/kubernetes

>tar -xzvf  kubernetes-src.tar.gz



>将二进制文件拷贝到指定路径

>cd /home/kubernetes/kubernetes/kubernetes && cp -r server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} /usr/local/bin/
>
>说明:kubernetes-server-linux-amd64.tar.gz 已经包含了 client(kubectl) 二进制文件，所以不用单独下载kubernetes-client-linux-amd64.tar.gz文件




### 安装完成之后，接下来就是配置

##### kube-apiserver

创建一个kube-apiserver文件:

vi /usr/lib/systemd/system/kube-apiserver.service

	[Unit]
	Description=Kubernetes API Service
	Documentation=https://github.com/GoogleCloudPlatform/kubernetes
	After=network.target
	After=etcd.service

	[Service]
	EnvironmentFile=-/etc/kubernetes/config
	EnvironmentFile=-/etc/kubernetes/apiserver
	ExecStart=/usr/local/bin/kube-apiserver \
		    $KUBE_LOGTOSTDERR \
		    $KUBE_LOG_LEVEL \
		    $KUBE_ETCD_SERVERS \
		    $KUBE_API_ADDRESS \
		    $KUBE_API_PORT \
		    $KUBELET_PORT \
		    $KUBE_ALLOW_PRIV \
		    $KUBE_SERVICE_ADDRESSES \
		    $KUBE_ADMISSION_CONTROL \
		    $KUBE_API_ARGS
	Restart=on-failure
	Type=notify
	LimitNOFILE=65536

	[Install]
	WantedBy=multi-user.target


##### /etc/kubernetes/config内容

	mkdir -p /etc/kubernetes && cd /etc/kubernetes

vi config：

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
	KUBE_ALLOW_PRIV="--allow-privileged=true"
	
	# How the controller-manager, scheduler, and proxy find the apiserver
	#KUBE_MASTER="--master=http://sz-pg-oam-docker-test-001.tendcloud.com:8080"
	KUBE_MASTER="--master=http://192.168.122.148:8080"


该配置文件同时被kube-apiserver、kube-controller-manager、kube-scheduler、kubelet、kube-proxy使用


##### /etc/kubernetes/apiserver

	cd /etc/kubernetes

vi apiserver:

	###
	## kubernetes system config
	##
	## The following values are used to configure the kube-apiserver
	##
	#
	## The address on the local server to listen to.
	#KUBE_API_ADDRESS="--insecure-bind-address=sz-pg-oam-docker-test-001.tendcloud.com"
	KUBE_API_ADDRESS="--advertise-address=192.168.122.143 --bind-address=192.168.122.143 --insecure-bind-address=192.168.122.143"
	#
	## The port on the local server to listen on.
	#KUBE_API_PORT="--port=8080"
	#
	## Port minions listen on
	#KUBELET_PORT="--kubelet-port=10250"
	#
	## Comma separated list of nodes in the etcd cluster
	KUBE_ETCD_SERVERS="--etcd-servers=https://192.168.122.143:2379"
	#
	## Address range to use for services
	KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
	#
	## default admission control policies
	KUBE_ADMISSION_CONTROL="--admission-control=ServiceAccount,NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"
	#
	## Add your own!
	KUBE_API_ARGS="--authorization-mode=RBAC --runtime-config=rbac.authorization.k8s.io/v1beta1 --kubelet-https=true --experimental-bootstrap-token-auth --token-auth-file=/etc/kubernetes/token.csv --service-node-port-range=30000-32767 --tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem --etcd-cafile=/etc/kubernetes/ssl/ca.pem --etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem --etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem --enable-swagger-ui=true --apiserver-count=3 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/var/lib/audit.log --event-ttl=1h"




--authorization-mode=RBAC 指定在安全端口使用 RBAC 授权模式，拒绝未通过授权的请求；

kube-scheduler、kube-controller-manager 一般和 kube-apiserver 部署在同一台机器上，它们使用非安全端口和 kube-apiserver通信;
kubelet、kube-proxy、kubectl 部署在其它 Node 节点上，如果通过安全端口访问 kube-apiserver，则必须先通过 TLS 证书认证，再通过 RBAC 授权；

kube-proxy、kubectl 通过在使用的证书里指定相关的 User、Group 来达到通过 RBAC 授权的目的；

如果使用了 kubelet TLS Boostrap 机制，则不能再指定 --kubelet-certificate-authority、--kubelet-client-certificate 和 --kubelet-client-key 选项，否则后续 kube-apiserver 校验 kubelet 证书时出现 ”x509: certificate signed by unknown authority“ 错误；

--admission-control 值必须包含 ServiceAccount；

--bind-address 不能为 127.0.0.1；

runtime-config配置为rbac.authorization.k8s.io/v1beta1，表示运行时的apiVersion；

--service-cluster-ip-range 指定 Service Cluster IP 地址段，该地址段不能路由可达；

缺省情况下 kubernetes 对象保存在 etcd /registry 路径下，可以通过 --etcd-prefix 参数进行调整；



启动:

	 systemctl stop firewalld
	$ systemctl daemon-reload
	$ systemctl enable kube-apiserver
	$ systemctl start kube-apiserver
	$ systemctl status kube-apiserver


#####  kube-apiser的启动问题
发现kube-apiserver启动不了，journalctl -xe，查看发现报错：

	Subject: Process /usr/bin/kube-apiserver could not be executed

原来是/usr/bin/在这没有可执行文件，发现问题，是在kube-apiserver.service的启动文件中，因为偷懒，直接上传了以前的文件（通过yum安装的，可执行文件默认在/usr/bin中），而没有改开始启动程序的目录,解决复制可执行程序到/usr/bin/或更改service文件


方法1：复制一份可执行文件到/usr/bin里面:

	cd /home/kubernetes/kubernetes/kubernetes && cp -r server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} /usr/bin/

#####  方法2：更改kube-apiserver.service的配置文件为(本案例采用此方法):

	ExecStart=/usr/local/bin/kube-apiserver/


结果发现还是启动不了:

	 Failed at step USER spawning /usr/local/bin/kube-apiserver: No such process

仔细看看，发现了kube-apiserver.service中有一个User=kube,而可执行文件kube-apiserver的用户组是root/root

vi /usr/lib/systemd/system/kube-apiserver.service将User=kube改为:

	User=root

然后启动:

	systemctl daemon-reload
	systemctl enable kube-apiserver
	systemctl start kube-apiserver
	systemctl status kube-apiserver

很完美的启动了！！！



### kube-controller-manager 启动

vi /usr/lib/systemd/system/kube-controller-manager.service



启动:

	systemctl daemon-reload
	systemctl enable kube-controller-manager
	systemctl start kube-controller-manager



### kube-scheduler 启动


vi /usr/lib/systemd/system/kube-scheduler.service


启动:

	 systemctl daemon-reload
	 systemctl enable kube-scheduler
	 systemctl start kube-scheduler



### 验证

	[root@localhost kubernetes]# curl -k http://192.168.122.148:8080/version
	{
	  "major": "1",
	  "minor": "8",
	  "gitVersion": "v1.8.4",
	  "gitCommit": "9befc2b8928a9426501d3bf62f72849d5cbcd5a3",
	  "gitTreeState": "clean",
	  "buildDate": "2017-11-20T05:17:43Z",
	  "goVersion": "go1.8.3",
	  "compiler": "gc",
	  "platform": "linux/amd64"
	}[root@localhost kubernetes]# 

k8s版本：

	[root@localhost kubernetes]# kubectl version
	Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.4", GitCommit:"9befc2b8928a9426501d3bf62f72849d5cbcd5a3", GitTreeState:"clean", BuildDate:"2017-11-20T05:28:34Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
	The connection to the server localhost:8080 was refused - did you specify the right host or port?
	[root@localhost kubernetes]# 


开放8080端口

vi /etc/kubernetes/apiserver
	
	KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"
	KUBE_API_PORT="--port=8080" #将注释去掉
	之后重启apiserver

	systemctl restart kube-apiserver


之后运行:

	[root@localhost kubernetes]# kubectl version
	Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.4", GitCommit:"9befc2b8928a9426501d3bf62f72849d5cbcd5a3", GitTreeState:"clean", BuildDate:"2017-11-20T05:28:34Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
	Server Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.4", GitCommit:"9befc2b8928a9426501d3bf62f72849d5cbcd5a3", GitTreeState:"clean", BuildDate:"2017-11-20T05:17:43Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
	[root@localhost kubernetes]# 



查看master节点功能:

	[root@localhost kubernetes]# kubectl get componentstatuses
	NAME                 STATUS      MESSAGE                                        ERROR
	scheduler            Healthy     ok                                             
	etcd-0               Unhealthy   Get https://192.168.122.148:2379/health: EOF   
	controller-manager   Healthy     ok                                             
	[root@localhost kubernetes]# 


发现etcd不健康，参照上面的etcd(https)配置一下即可!

	[root@localhost system]# kubectl get componentstatuses
	NAME                 STATUS    MESSAGE              ERROR
	scheduler            Healthy   ok                   
	controller-manager   Healthy   ok                   
	etcd-0               Healthy   {"health": "true"}   
	[root@localhost system]# 




## node节点部分

通过最上面几步配置，发现没有node加入进来,这是正常的！

	[root@localhost ~]# kubectl get node
	No resources found.
	[root@localhost ~]# 


### 在node节点检查证书文件是否存在

	[root@localhost ~]# ls /etc/kubernetes/ssl
	admin-key.pem  admin.pem  ca-key.pem  ca.pem  kube-proxy-key.pem  kube-proxy.pem  kubernetes-key.pem  kubernetes.pem
	[root@localhost ~]# 
	[root@localhost ~]# ls /etc/kubernetes/
	apiserver  bootstrap.kubeconfig  config  controller-manager  kubelet  kube-proxy.kubeconfig  proxy  scheduler  ssl  token.csv
	[root@localhost ~]# 


### 修改flanneld的网络，使得支持https

	yum install -y flannel  #装过了可跳过

vi /usr/lib/systemd/system/flanneld.service

	[Unit]
	Description=Flanneld overlay address etcd agent
	After=network.target
	After=network-online.target
	Wants=network-online.target
	After=etcd.service
	Before=docker.service
	
	[Service]
	Type=notify
	EnvironmentFile=/etc/sysconfig/flanneld
	EnvironmentFile=-/etc/sysconfig/docker-network
	ExecStart=/usr/bin/flanneld-start \
	  -etcd-endpoints=${ETCD_ENDPOINTS} \
	  -etcd-prefix=${ETCD_PREFIX} \
	  $FLANNEL_OPTIONS
	ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
	Restart=on-failure
	
	[Install]
	WantedBy=multi-user.target
	RequiredBy=docker.service

修改:
<font color=#ff4757 size=3 face="黑体">

	-etcd-endpoints=${ETCD_ENDPOINTS} \
	-etcd-prefix=${ETCD_PREFIX} \
</font>


vi /etc/sysconfig/flanneld,在FLANNEL_OPTIONS中增加TLS的配置：


	# Flanneld configuration options  

	# etcd url location.  Point this to the server where etcd runs
	ETCD_ENDPOINTS="https://192.168.122.148:2379"
	
	# etcd config key.  This is the configuration key that flannel queries
	# For address range assignment
	ETCD_PREFIX="/coreos.com/network" #这个可根据自己的需要定制
	
	# Any additional options that you want to pass
	FLANNEL_OPTIONS="-etcd-cafile=/etc/kubernetes/ssl/ca.pem -etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem -etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem"


在etcd中修改之前设置过的网络,执行下面的命令为docker分配IP地址段:

之前的命令是：

	# etcdctl  set /coreos.com/network/config '{"Network":"10.254.0.0/16"}'

创建：

	etcdctl --endpoints=https://192.168.122.148:2379 \
 	 	--ca-file=/etc/kubernetes/ssl/ca.pem \
  		--cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  		--key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	mkdir /coreos.com/network


设置网络，如果你要使用host-gw模式，可以直接将vxlan改成host-gw即可：

	etcdctl --endpoints=https://192.168.122.148:2379 \
	  --ca-file=/etc/kubernetes/ssl/ca.pem \
	  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
	  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	  mk /coreos.com/network/config '{"Network":"10.254.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}'


运行：

	# source /run/flannel/subnet.env

	[root@localhost ~]# cat /run/flannel/subnet.env
	FLANNEL_NETWORK=10.254.0.0/16
	FLANNEL_SUBNET=10.254.96.1/24
	FLANNEL_MTU=1472
	FLANNEL_IPMASQ=false
	[root@localhost ~]# 

	# docker daemon --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU} &

	systemctl daemon-reload
	systemctl enable flanneld
	systemctl stop docker 
	systemctl restart flanneld
	systemctl status flanneld -l


发现重启不成功，systemctl status flanneld -l查看之后，发现

	-etcd-endpoints=https://192.168.122.148:2379 -etcd-prefix=/coreos.com/network  -etcd-endpoints= -etcd-prefix=

后面跟着2个空的配置，所以将/usr/lib/systemd/system/flanneld.service的配置，重新设置一遍:


<font color=#ff4757 size=3 face="黑体">

	-etcd-endpoints=https://192.168.122.148:2379 \
	-etcd-prefix=/coreos.com/network \
</font>

重启，
	
	systemctl daemon-reload
	systemctl enable flanneld
	systemctl stop docker 
	systemctl restart flanneld
	systemctl status flanneld -l
	systemctl start docker

即可成功!!


ip addr显示：

	[root@localhost ~]# ip addr
	1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
	    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
	    inet 127.0.0.1/8 scope host lo
	       valid_lft forever preferred_lft forever
	    inet6 ::1/128 scope host 
	       valid_lft forever preferred_lft forever
	2: eno16777736: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
	    link/ether 00:0c:29:e1:6d:4e brd ff:ff:ff:ff:ff:ff
	    inet 192.168.122.148/24 brd 192.168.122.255 scope global dynamic eno16777736
	       valid_lft 1120sec preferred_lft 1120sec
	    inet6 fe80::20c:29ff:fee1:6d4e/64 scope link 
	       valid_lft forever preferred_lft forever
	3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN 
	    link/ether 02:42:a1:88:c6:72 brd ff:ff:ff:ff:ff:ff
	    inet 10.254.69.1/24 scope global docker0
	       valid_lft forever preferred_lft forever
	5: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN 
	    link/ether ba:f9:3d:81:c6:45 brd ff:ff:ff:ff:ff:ff
	    inet 10.254.69.0/32 scope global flannel.1
	       valid_lft forever preferred_lft forever
	    inet6 fe80::b8f9:3dff:fe81:c645/64 scope link 
	       valid_lft forever preferred_lft forever
	[root@localhost ~]# 


docker0和flannel网桥会在同一个子网中！！




查看etcd中的网络

	etcdctl --endpoints=${ETCD_ENDPOINTS} \
	  --ca-file=/etc/kubernetes/ssl/ca.pem \
	  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
	  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	  ls /coreos.com/network/subnets

显示：

	/coreos.com/network/subnets/10.254.69.0-24

配置

	etcdctl --endpoints=${ETCD_ENDPOINTS} \
	  --ca-file=/etc/kubernetes/ssl/ca.pem \
	  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
	  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
	  get /coreos.com/network/config


显示：

	{"Network":"10.254.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}
	


### 安装和配置 kubelet

>kubelet 启动时向 kube-apiserver 发送 TLS bootstrapping 请求，需要先将 bootstrap token 文件中的 kubelet-bootstrap 用户赋予 system:node-bootstrapper cluster 角色(role)， 然后 kubelet 才能有权限创建认证请求(certificate signing requests)：

	cd /etc/kubernetes
	kubectl create clusterrolebinding kubelet-bootstrap \
	  --clusterrole=system:node-bootstrapper \
	  --user=kubelet-bootstrap

--user=kubelet-bootstrap 是在 /etc/kubernetes/token.csv 文件中指定的用户名，同时也写入了 /etc/kubernetes/bootstrap.kubeconfig 文件



### 下载最新的 kubelet 和 kube-proxy 二进制文件


	wget https://dl.k8s.io/v1.8.4/kubernetes-server-linux-amd64.tar.gz
	tar -xzvf kubernetes-server-linux-amd64.tar.gz
	cd kubernetes
	tar -xzvf  kubernetes-src.tar.gz
	cp -r ./server/bin/{kube-proxy,kubelet} /usr/local/bin/


由于现在是master和node在一台主机上，所以可以跳过这步!!


vi /usr/lib/systemd/system/kubelet.service

将

	ExecStart=/usr/bin/kubelet 改为：ExecStart=/usr/local/bin/kubelet



vi /etc/kubernetes/kubelet


	###
	# kubernetes kubelet (minion) config
	
	# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
	KUBELET_ADDRESS="--address=0.0.0.0"
	
	# The port for the info server to serve on
	KUBELET_PORT="--port=10250"
	
	# You may leave this blank to use the actual hostname
	KUBELET_HOSTNAME="--hostname-override=192.168.122.148"
	
	# location of the api-server
	KUBELET_API_SERVER="--api-servers=http://192.168.122.148:8080"
	
	# pod infrastructure container
	KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"
	
	# Add your own!
	KUBELET_ARGS="--cluster_dns=10.254.200.200 \
	--cluster-domain=cluster.local \
	--cgroup-driver=systemd  \
	--experimental-bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
	--kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
	--require-kubeconfig \
	--cert-dir=/etc/kubernetes/ssl \
	--hairpin-mode promiscuous-bridge \
	--serialize-image-pulls=false"


--address 不能设置为 127.0.0.1，否则后续 Pods 访问 kubelet 的 API 接口时会失败，因为 Pods 访问的 127.0.0.1 指向自己而不是 kubelet


启动：

	systemctl daemon-reload
	systemctl enable kubelet
	systemctl start kubelet
	systemctl status kubelet

启动失败(journalctl -xe或journalctl或journalctl -xe -u kubelet)：

 Failed at step CHDIR spawning /usr/local/bin/kubelet: No such file or directory

检查/usr/lib/systemd/system/kubelet.service，发现WorkingDirectory=/var/lib/kubelet：

	这个目录不存在/var/lib/kubelet
	
	mkdir -p /var/lib/kubelet


重新启动kubelet,发现还是失败，只不过报错变成了：

	Specifies interval for kubelet to calculate and cache the volume disk usage for...To disable volume calculations, set to 0


解决：


找到的方法：

	please switchoff your swap memory i faced same problem and when i remove swap entry from my /etc/fstab file .then it worked in my case.also do swapoff

	

关闭swap

	swapoff -a

再把/etc/fstab文件中带有swap的行删了,没有就无视


结果还是没用，最后求助得到的结果是:

1.8.x版本已经取消了，所以在/etc/kubernetes/kubelet中删掉,下面这一行

	# location of the api-server
	KUBELET_API_SERVER="--api-servers=http://192.168.122.148:8080"

即可启动！！


###注意: kubelet 配置与 1.7 版本有一定改动

>增加 --fail-swap-on=false 选项，否则可能导致在开启 swap 分区的机器上无法启动 kubelet，详细可参考 [CHANGELOG](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#before-upgrading) (before-upgrading 第一条)
移除 --require-kubeconfig 选项，已经过时废弃




### 证书认证（master通过 kublet 的 TLS 证书请求）

> kubelet 首次启动时向 kube-apiserver 发送证书签名请求，必须通过后 kubernetes 系统才会将该 Node 加入到集群。
> —kubeconfig=/etc/kubernetes/kubelet.kubeconfig中指定的kubelet.kubeconfig文件在第一次启动kubelet之前并不存在，当通过CSR请求后会自动生成kubelet.kubeconfig文件，如果你的节点上已经生成了~/.kube/config文件，你可以将该文件拷贝到该路径下，并重命名为kubelet.kubeconfig，所有node节点可以共用同一个kubelet.kubeconfig文件，这样新添加的节点就不需要再创建CSR请求就能自动添加到kubernetes集群中。同样，在任意能够访问到kubernetes集群的主机上使用kubectl —kubeconfig命令操作集群时，只要使用~/.kube/config文件就可以通过权限认证，因为这里面已经有认证信息并认为你是admin用户，对集群拥有所有权限


查看证书：

	[root@localhost ~]# kubectl get csr
	NAME                                                   AGE       REQUESTOR           CONDITION
	node-csr-7m2rt_8iaGmi014H_1qymihTQ3HuxLpJwAkJp_ffCWM   20m       kubelet-bootstrap   Pending
	[root@localhost ~]# 


通过证书（上面的Pending表示未授权的CSR 请求）：

	[root@localhost ~]#  kubectl certificate approve node-csr-7m2rt_8iaGmi014H_1qymihTQ3HuxLpJwAkJp_ffCWM
	certificatesigningrequest "node-csr-7m2rt_8iaGmi014H_1qymihTQ3HuxLpJwAkJp_ffCWM" approved
	[root@localhost ~]# 


通过证书之后，再次查看:

	[root@localhost ~]# kubectl get csr
	NAME                                                   AGE       REQUESTOR           CONDITION
	node-csr-7m2rt_8iaGmi014H_1qymihTQ3HuxLpJwAkJp_ffCWM   22m       kubelet-bootstrap   Approved,Issued
	[root@localhost ~]# 


自动生成了 kubelet kubeconfig 文件和公私钥：

	[root@localhost ~]# ls -l /etc/kubernetes/kubelet.kubeconfig
	-rw-------. 1 root root 2282 Nov 23 06:33 /etc/kubernetes/kubelet.kubeconfig
	[root@localhost ~]# ls -l /etc/kubernetes/ssl/kubelet*
	-rw-r--r--. 1 root root 1050 Nov 23 06:33 /etc/kubernetes/ssl/kubelet-client.crt
	-rw-------. 1 root root  227 Nov 23 06:10 /etc/kubernetes/ssl/kubelet-client.key
	-rw-r--r--. 1 root root 1119 Nov 23 06:10 /etc/kubernetes/ssl/kubelet.crt
	-rw-------. 1 root root 1675 Nov 23 06:10 /etc/kubernetes/ssl/kubelet.key
	[root@localhost ~]# 


注：假如你更新kubernetes的证书，只要没有更新token.csv，当重启kubelet后，该node就会自动加入到kuberentes集群中，而不会重新发送certificaterequest，也不需要在master节点上执行kubectl certificate approve操作。前提是不要删除node节点上的/etc/kubernetes/ssl/kubelet*和/etc/kubernetes/kubelet.kubeconfig文件。否则kubelet启动时会提示找不到证书而失败



查看是否有node节点进来：

	[root@localhost ~]#  kubectl get node
	No resources found.

报错：

	Failed to list *v1.Node: nodes is forbidden: User "system:node:192.168.122.148" cannot list nodes at the cluster scope


将/etc/kubernetes/apiserver修改为:

	KUBE_API_ADDRESS="--advertise-address=192.168.122.148 --insecure-bind-address=127.0.0.1 --bind-address=192.168.122.148"
	KUBE_API_PORT="--insecure-port=8080 --secure-port=6443"

	KUBE_ADMISSION_CONTROL增加NodeRestriction参数

	KUBE_API_ARGS中的
	--authorization-mode=RBAC变成--authorization-mode=RBAC,Node
	

重启即可：

	systemctl restart kube-apiserver


### 1.8.x APISERVER新变化

	1.移除了 --runtime-config=rbac.authorization.k8s.io/v1beta1 配置，因为 RBAC 已经稳定，被纳入了 v1 api，不再需要指定开启
	
	2.--authorization-mode 授权模型增加了 Node 参数，因为 1.8 后默认 system:node role 不会自动授予 system:nodes 组，具体请参看 [CHANGELOG](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#before-upgrading) (before-upgrading 段最后一条说明)
	
	3.由于以上原因， --admission-control 同时增加了 NodeRestriction 参数，关于关于节点授权器请参考 [Using Node Authorization](https://kubernetes.io/docs/admin/authorization/node/)
	
	4.增加 --audit-policy-file 参数用于指定高级审计配置，具体可参考 [CHANGELOG](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#before-upgrading) (before-upgrading 第四条)、 [Advanced audit](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/#advanced-audit)
	
	
	5.移除 --experimental-bootstrap-token-auth 参数，更换为 --enable-bootstrap-token-auth ，详情参考 [CHANGELOG](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#before-upgrading) (Auth 第二条)





再次查看:


	[root@localhost kubernetes]# kubectl get nodes
	NAME              STATUS    ROLES     AGE       VERSION
	192.168.122.148   Ready     <none>    5m        v1.8.4
	[root@localhost kubernetes]# 



### 配置kube-proxy


vi /usr/lib/systemd/system/kube-proxy.service:

	将ExecStart=/usr/bin/kube-proxy 替换成

	ExecStart=/usr/local/bin/kube-proxy 


vi /etc/kubernetes/proxy:

	KUBE_PROXY_ARGS="--bind-address=192.168.122.148 \
	--hostname-override=192.168.122.148 \
	--kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
	--cluster-cidr=10.254.0.0/16"


启动kube-proxy:


	systemctl daemon-reload
	systemctl enable kube-proxy
	systemctl start kube-proxy
	systemctl status kube-proxy



### 验证nginx


	kubectl run nginx --replicas=2 --labels="run=load-balancer-example" --image=nginx:1.9  --port=80


	kubectl expose deployment nginx --type=NodePort --name=example-service


发现查看pod失败，没有资源可用：

	发现curl -k http://192.168.122.148:8080不可用,将/etc/kubernetes/config中的

	KUBE_MASTER="--master=http://192.168.122.148:8080"

	改为：

	KUBE_MASTER="--master=http://127.0.0.1:8080"


重启所有服务，即可查看资源！


	[root@localhost kubernetes]# kubectl get pods  -o wide
	NAME                    READY     STATUS    RESTARTS   AGE       IP        NODE
	nginx-c999fd64f-4jsv7   0/1       Pending   0          6s        <none>    <none>
	nginx-c999fd64f-gpnlk   0/1       Pending   0          6s        <none>    <none>
	[root@localhost kubernetes]# 


删除nginx:

	kubectl get deployments
	kubectl delete  deployments nginx

	或强制删除pod

	 kubectl delete pods <pod> --grace-period=0 --force 


测试nginx:

查看访问地址：

	[root@localhost ~]# kubectl describe svc example-service
	Name:                     example-service
	Namespace:                default
	Labels:                   run=load-balancer-example
	Annotations:              <none>
	Selector:                 run=load-balancer-example
	Type:                     NodePort
	IP:                       10.254.234.253
	Port:                     <unset>  80/TCP
	TargetPort:               80/TCP
	NodePort:                 <unset>  31831/TCP
	Endpoints:                10.254.69.2:80,10.254.69.3:80
	Session Affinity:         None
	External Traffic Policy:  Cluster
	Events:                   <none>
	[root@localhost ~]# 


测试访问地址：

	[root@localhost ~]# curl 10.254.69.2:80
	<!DOCTYPE html>
	<html>
	<head>
	<title>Welcome to nginx!</title>
	<style>
	    body {
	        width: 35em;
	        margin: 0 auto;
	        font-family: Tahoma, Verdana, Arial, sans-serif;
	    }
	</style>
	</head>
	<body>
	<h1>Welcome to nginx!</h1>
	<p>If you see this page, the nginx web server is successfully installed and
	working. Further configuration is required.</p>
	
	<p>For online documentation and support please refer to
	<a href="http://nginx.org/">nginx.org</a>.<br/>
	Commercial support is available at
	<a href="http://nginx.com/">nginx.com</a>.</p>
	
	<p><em>Thank you for using nginx.</em></p>
	</body>
	</html>
	[root@localhost ~]# 


	

发现nginx一直处于pending状态：

查看systemctl status kube-scheduler发现，master地址是:192.168.122.148:8080，这个地址不能访问，所以修改为：

vi /etc/kubernetes/scheduler :

	KUBE_SCHEDULER_ARGS="--leader-elect=true --address=127.0.0.1 --master=http://127.0.0.1:8080"

然后再重启systemctl restart kube-scheduler服务

	docker pull index.tenxcloud.com/google_containers/pause:2.0

	docker tag index.tenxcloud.com/google_containers/pause:2.0 gcr.io/google_containers/pause:2.0

vi /etc/sysconfig/docker

	OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false'

改成：

	OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false --insecure-registry gcr.io'




问题汇总：

Q1： curl 127.0.0.1:8080能访问，curl 192.168.122.148:8080不能访问!


A1:	将这个地址设置成： --insecure-bind-address=192.168.122.148,即可访问，但是127.0.0.1：8080又不能访问了

	所以还是将它设置成：

	--insecure-bind-address=0.0.0.0


Q2: pod一直在创建中，且systemctl status kubectl 显示 open /etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt no such file or directory

A2:

	yum install *rhsm*
	docker pull registry.access.redhat.com/rhel7/pod-infrastructure:latest








参考文档:

[https://github.com/kubernetes/kubernetes/issues/54542](https://github.com/kubernetes/kubernetes/issues/54542)

	

	



	









	
	


	



	

