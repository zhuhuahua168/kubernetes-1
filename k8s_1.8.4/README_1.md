### kubernets 1.8官方安装文档

### 快速安装

	#wget https://github.com/kubernetes/kubernetes/releases/download/v1.8.3/kubernetes.tar.gz
	#tar zxvf kubernetes.tar.gz

	systemctl disable firewalld
	systemctl stop firewalld

	yum install -y etcd kubernetes

	vi /etc/sysconfig/docker

将

	OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false'

变成

	OPTIONS='--selinux-enabled=false --insecure-registry gcr.io'


master启动:

	systemctl start etcd
	systemctl start docker
	systemctl start kube-apiserver
	systemctl start kube-controller-manager
	systemctl start kube-scheduler
	systemctl start kubelet
	systemctl start kube-proxy

	

版本:

	[root@iZuf62kvdczytdiot4r4spZ kubernetes]# kubectl --version
	Kubernetes v1.5.2


node启动:

	yum install -y docker
	yum install -y kubernetes


官方基础镜像:

	docker pull index.tenxcloud.com/google_containers/pause:2.0
	docker tag index.tenxcloud.com/google_containers/pause:2.0 gcr.io/google_containers/pause:2.0
	


### 安装ui面板

由于墙的问题，所以将镜像更改为国内的，或者下载最新镜像。

	
	docker pull registry.cn-hangzhou.aliyuncs.com/google-containers/kubernetes-dashboard-init-amd64:v1.0.1
	docker pull registry.cn-hangzhou.aliyuncs.com/google-containers/kubernetes-dashboard-amd64:v1.7.1

打上标签
	
	docker tag registry.cn-hangzhou.aliyuncs.com/google-containers/kubernetes-dashboard-init-amd64:v1.0.1 gcr.io/google_containers/kubernetes-dashboard-init-amd64:v1.0.1

	docker tag registry.cn-hangzhou.aliyuncs.com/google-containers/kubernetes-dashboard-amd64:v1.7.1 gcr.io/google_containers/kubernetes-dashboard-amd64:v1.7.1

	kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml


选择正确的版本

	kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.5.1/src/deploy/kubernetes-dashboard.yaml

描述:

	kubectl describe -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.5.1/src/deploy/kubernetes-dashboard.yaml


	docker pull registry.cn-hangzhou.aliyuncs.com/kube_containers/kubernetes-dashboard-amd64:v1.5.1

	docker tag registry.cn-hangzhou.aliyuncs.com/kube_containers/kubernetes-dashboard-amd64:v1.5.1 gcr.io/google_containers/kubernetes-dashboard-amd64:v1.5.1

	kubectl get pods --all-namespaces

	kubectl describe pod kubernetes-dashboard-3203831700-9l6fv  --namespace=kube-system
	kubectl logs  kubernetes-dashboard-1583850781-rqj3n   --namespace=kube-system
	kubectl delete pod kubernetes-dashboard-1583850781-pnhn2 --namespace=kube-system


	 kubectl cluster-info


### 安装flannel
	
	yum install -y flannel

编辑配置文件:

	# vim /etc/sysconfig/flanneld

	# Flanneld configuration options  
	
	# etcd url location.  Point this to the server where etcd runs
	FLANNEL_ETCD="http://k8s-master1:2379"
	
	# etcd config key.  This is the configuration key that flannel queries
	# For address range assignment
	FLANNEL_ETCD_KEY="/coreos.com/network"                                                                                                                                                                                       
	
	# Any additional options that you want to pass
	#FLANNEL_OPTIONS=""
	
	# systemctl enable flanneld.service ; systemctl start flanneld.service



在master上的etcd配置文件/etc/etcd/etcd.conf,把localhost换成k8s-master

	ETCD_LISTEN_CLIENT_URLS="http://k8s-master1:2379"
	
	ETCD_ADVERTISE_CLIENT_URLS="http://k8s-master1:2379"

启动:

	etcdctl  set /coreos.com/network/config '{"Network":"10.254.0.0/16"}'
	systemctl stop docker
	systemctl start flanneld


etcd启动不了:

	etcdctl –-endpoints "http://47.100.76.132:2379,http://47.100.76.132:2380" ls 



### 问题

Q1:gcr.io被墙

A1:

	docker hub提供了一个很棒的功能，Automated Build。
	
	简单来说就是，你可以把你想要build的Docker Image的Dockerfile文件放到github上，然后github上开启对docker hub的授权（读权限就可以了），之后就可以在docker hub上根据这个Dockerfile来自动编译了。换句话说就是，Docker hub为我们提供了一个build的环境，你不需要本地build再push了。
	
	这样，我可以在Github上编写一个简单的只是FROM gcr.io/google_containers/xxx的Dockerfile，然后让docker hub来build Github上的Dockerfile，他们都在墙外，build自然没有问题；然后我再通过docker hub加速器取下来，这样就可以保证是官方发布的了，速度质量都可靠


Q2: kubectl get rc,get services都能看到资源，但是kubectl get pods查看不到资源

A2:
	原因是身份认证，参考之前的解决方案，为k8s配置认证证书。
	[点击查看解决方案](https://github.com/zouhuigang/kubernetes/blob/e8e061c86b02b72e85107c16019ce166f868ce1c/Heapster%2BInfluxDB%2BGrafana/README.md)

Q3:image pull failed for registry.access.redhat.com/rhel7/pod-infrastructure:latest,镜像一直下不下来,vi /etc/sysconfig/docker中增加，取消安全认证

	INSECURE_REGISTRY='--insecure-registry gcr.io' 

如果增加上面这个无效,也可以用下面这个

	OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false --insecure-registry gcr.io'


Q4:open /etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt
	
	把服务都重启一遍就好了

Q5:kubelet does not have ClusterDNS IP configured and cannot create Pod using "ClusterFirst"
或 Get http://47.100.76.132:8080/version: dial tcp 47.100.76.132:8080: getsockopt: connection refused

A5:

	The kubelet service needs a command-line flag to set the cluster DNS IP - it looks like you're running kube-dns, so you can get that IP by either running kubectl get services --namespace=kube-system or grabbing the IP from the "ClusterIP" field on the kube-dns service YAML or JSON config.

	Once you have the IP, you'll have to set the --cluster-dns command-line flag for kubelet.
	
	I haven't used kubeadm to setup a cluster, so I'm not sure how it runs the services and can't say how to change the command-line flags - hopefully somebody who knows can provide input for that piece.

	重新配置apiserver,config的KUBE_MASTER="--master=http://47.100.76.132:8080"

	访问ip即可，然后重启apiserver即可


Q6:启动kube-state-metrics-deployment监控镜像，报错
	Warning MissingClusterDNS       kubelet does not have ClusterDNS IP configured and cannot create Pod using "ClusterFirst" policy. Falling back to DNSDefault policy.

A6:

	配置kubelet中的vi /etc/kubernetes/kubelet,修改为如下参数：

	KUBELET_ADDRESS="--address=0.0.0.0"
	KUBELET_PORT="--port=10250" #如果关闭了，就开启
	KUBELET_HOSTNAME="--hostname-override=k8s-master1" #修改成节点的hostname，如：k8s-node1
	KUBELET_API_SERVER="--api-servers=http://k8s-master1:8080" #修改成master的hostname,需在/etc/hosts中配置ip映射


Q7:kubelet不能调度，具体表现在kubectl delete /create超时或不能删除pod等问题,
	kube-controller-manager.service holdoff time over, scheduling restart.
	timed out waiting for "mysql" to be synced

A7： kube-controller-manager控制器出问题了.
	确保/var/run/kubernetes中有kubelet.crt  kubelet.key 这2个文件
	最后发现是key的问题：
	
	KUBE_CONTROLLER_MANAGER_ARGS="--service-account-private-key-file=/var/run/kubernetes/apiserver.key \
     --root-ca-file=/var/run/kubernetes/ca.crt"

	将上面的清空，改为

	KUBE_CONTROLLER_MANAGER_ARGS=""
	即正常了


Q8:下载不下来镜像,报错open /etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt no such file or directory

A8:

	#yum install *rhsm*

	检查apiserver的8080端口是否可用



Q9:curl -v 10.254.0.1:443不能访问

	https://192.168.122.147:6443/swaggerapi/
	
	
	

	


[https://stackoverflow.com/questions/45837246/kubelet-does-not-have-clusterdns-ip-configured-and-cannot-create-pod-using-clus](https://stackoverflow.com/questions/45837246/kubelet-does-not-have-clusterdns-ip-configured-and-cannot-create-pod-using-clus)





### 参考文档

[http://colabug.com/863347.html](http://colabug.com/863347.html)

[http://blog.csdn.net/aixiaoyang168/article/details/78411511](http://blog.csdn.net/aixiaoyang168/article/details/78411511)

[https://segmentfault.com/a/1190000005345466](https://segmentfault.com/a/1190000005345466)

[http://blog.csdn.net/jinzhencs/article/details/51435020](http://blog.csdn.net/jinzhencs/article/details/51435020)

[http://www.jianshu.com/p/9527b485929f](http://www.jianshu.com/p/9527b485929f)

[https://www.sunmite.com/docker/k8s-errors-1.html](https://www.sunmite.com/docker/k8s-errors-1.html)

[https://mritd.me/2016/12/06/try-traefik-on-kubernetes/#13ingress](https://mritd.me/2016/12/06/try-traefik-on-kubernetes/#13ingress)

	


