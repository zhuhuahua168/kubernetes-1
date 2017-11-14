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





### 参考文档

[http://colabug.com/863347.html](http://colabug.com/863347.html)

[http://blog.csdn.net/aixiaoyang168/article/details/78411511](http://blog.csdn.net/aixiaoyang168/article/details/78411511)

[https://segmentfault.com/a/1190000005345466](https://segmentfault.com/a/1190000005345466)

[http://blog.csdn.net/jinzhencs/article/details/51435020](http://blog.csdn.net/jinzhencs/article/details/51435020)

[http://www.jianshu.com/p/9527b485929f](http://www.jianshu.com/p/9527b485929f)

	


