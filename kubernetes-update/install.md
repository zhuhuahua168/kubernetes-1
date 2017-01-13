###初始化

    yum install -y docker etcd flannel


systemctl enable docker && systemctl start docker

安装1.3版本:

	# tar zxvf kubernetes1.3.tar.gz # 解压二进制包
	# cd kubernetes/server
	# tar zxvf kubernetes-server-linux-amd64.tar.gz  # 解压master所需的安装包
	# cd kubernetes/server/bin/
	# cp kube-apiserver kube-controller-manager kubectl kube-scheduler /usr/bin #把master需要的程序，拷贝到/usr/bin下，也可以设置环境变量达到相同目的
	# scp kubelet kube-proxy root@172.20.30.21:~  # 把minion需要的程序，scp发送到minion上
	# scp kubelet kube-proxy root@172.20.30.19:~
	# scp kubelet kube-proxy root@172.20.30.20:~



### 控制面板


    kubectl create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml


查看：

	kubectl describe pods kubernetes-dashboard --namespace=kube-system

    kubectl describe endpoints --namespace=kube-system


### 访问地址

http://192.168.122.135:8080/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/workload?namespace=kube-system


### node上部署flannel

	yum local install flannel-0.5.5-1.fc24.x86_64.rpm

查看ip网络

	ip -4 a|grep inet

输出：

	inet 127.0.0.1/8 scope host lo
    inet 192.168.122.137/24 brd 192.168.122.255 scope global dynamic eno16777736
    inet 172.17.0.1/16 scope global docker0

查看etcd所有网络值：

curl -s http://fed-master:4001/v2/keys/coreos.com/network/subnets | python -mjson.tool

启动flanneld

 flanneld -iface="eth0" -etcd-endpoints="http://k8s-masterL2379" &>/dev/null  &



ETCDCTL_ENDPOINT=http://10.128.6.27:2379,http://10.128.109.98:2379,http://10.128.7.34:2379 etcdctl get /coreos.com/network/config

ETCDCTL_ENDPOINT=http://k8s-master:2379 etcdctl cluster-health

### 安装iptables

	1、关闭firewall：
	systemctl stop firewalld.service #停止firewall
	systemctl disable firewalld.service #禁止firewall开机启动

	yum install iptables-services

###
yum install advance-toolchain-at9.0-devel -y

curl -v http://k8s-master:2379/v2/keys


问题：

A:定位“kubernetes pod卡在ContainerCreating状态”问题的方法

Q:kubernetes1.3.x版本需要pause:2.0版本的。不然一直下不下来镜像

    docker pull index.tenxcloud.com/google_containers/pause:2.0

	docker tag index.tenxcloud.com/google_containers/pause:2.0 gcr.io/google_containers/pause:2.0


参考文档：

[http://suqun.github.io/2016/09/07/dockerjavamicroservice2/](http://suqun.github.io/2016/09/07/dockerjavamicroservice2/)

[https://mengxd.wordpress.com/tag/kubernetes/](https://mengxd.wordpress.com/tag/kubernetes/)