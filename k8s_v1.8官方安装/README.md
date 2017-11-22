### 手动在CentOS7.2上部署kubernetes1.6集群

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
	

### 安装docker

 	yum install -y docker



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


	



	

