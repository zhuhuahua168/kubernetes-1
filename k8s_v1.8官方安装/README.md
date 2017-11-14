### github安装

环境:

	CentOS 7.x
	master:47.100.76.132


所有节点彼此网络互通，并且master1 SSH 登入其他节点为 passwdless。
所有防火墙与 SELinux 已关闭。如 CentOS：

	systemctl stop firewalld && systemctl disable firewalld
	setenforce 0
	vi /etc/selinux/config
	SELINUX=disabled



修改主机名称:

	查看主机状态：
	hostnamectl status

	修改:
	hostnamectl --static set-hostname k8s-master1

断开重连，即可修改成功!


修改hosts

	vi /etc/hosts

	[root@iZuf62kvdczytdiot4r4spZ etc]# cat hosts
	127.0.0.1 localhost iZuf62kvdczytdiot4r4spZ
	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
	10.81.128.152 iZuf62kvdczytdiot4r4spZ




测试：

	kubectl create -f mysql-rc.yaml
	kubectl create -f mysql-svc.yaml

	kubectl create -f myweb-rc.yaml
	kubectl create -f myweb-svc.yaml

问题汇总:

Q1:在服务器上用curl 127.0.0.1:30001能得到请求，但是外部却不能访问

A1:	

	查看防火墙,firewall-cmd --state
	检查到iptables中的FORWARD链有一条拒绝的规则
	6    REJECT     all  --  0.0.0.0/0            0.0.0.0/0            reject-with icmp-host-prohibited 

	#删除该规则，即可访问了
	iptables -t filter -D FORWARD 6 


参考文档:

[https://kubernetes.io/docs/setup/independent/install-kubeadm/](https://kubernetes.io/docs/setup/independent/install-kubeadm/)