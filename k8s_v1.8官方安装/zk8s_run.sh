#!/bin/bash
#######################################################
# $Name:         zk8s_run.sh
# $Version:      v1.0
# $Function:     启动or重启集群
# $Author:       邹慧刚
# $organization: https://www.anooc.com/
# $Create Date:  2017-11-17
# $Description:  使用前为启动脚本授予执行权限 chmod +x zk8s_run.sh
# 删除node kubectl delete node 10.31.31.29 或 etcdctl ls /registry/minions   etcdctl rm  /registry/minions/10.31.31.181
#######################################################

#判断证书文件是否存在,为0则都存在,为1则至少有一个不存在
private_cert_exits(){
	if [ -f /var/run/kubernetes/ca.crt ] && [ -f /var/run/kubernetes/ca.key ] && [ -f /var/run/kubernetes/ca.srl ] \
		&& [ -f /var/run/kubernetes/server.crt ] && [ -f /var/run/kubernetes/server.csr ]&& [ -f /var/run/kubernetes/server.key ];then
		return 1;
	else
		return 0;
	fi
}

#证书存在，则不重新生成
private_make_cert(){
	private_cert_exits; #调用函数
	is_exits=$?   #得到刚刚调用函数的返回值
	if [ $is_exits == 0 ];then
		do_openssl
	fi
}


#启动函数
do_start(){
	private_make_cert;

	for SERVICES in etcd flanneld docker kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy haproxy
	do 
	systemctl start $SERVICES
	systemctl status $SERVICES 
	done
}


do_status(){
	for SERVICES in etcd flanneld docker kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy haproxy
	do 
	systemctl status $SERVICES 
	done
}

do_stop(){
	for SERVICES in etcd flanneld docker kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy haproxy
	do 
	systemctl stop $SERVICES 
	done
}

#重启服务
do_restart(){
	for SERVICES in etcd flanneld docker kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy haproxy
	do 
	systemctl restart $SERVICES
	done
}

#生成并复制证书文件到指定目录,生成6个证书
do_openssl(){
	mkdir -p /home/k8s-cert && cd /home/k8s-cert
	openssl genrsa -out ca.key 2048
	openssl req -x509 -new -nodes -key ca.key -subj "/CN=master.k8s.com" -days 5000 -out ca.crt
	openssl genrsa -out server.key 2048
	openssl req -new -key server.key -subj "/CN=k8s-master1" -out server.csr
	openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 5000
	#复制证书到指定目录
	cp *.* /var/run/kubernetes/
}


#命令帮助
shell_usage(){

 	echo "Usage: $0 (start|restart|stop|status|openssl)"
}


#启动函数
main(){
	#switch切换函数
    case $1 in
		start)
			do_start
    		;;
		restart)
   			 do_restart
			;;
		stop)
			 do_stop
			;;
		status)
			 do_status
			;;
		openssl)
			 do_openssl
			;;
		*)
			shell_usage;
			exit 1
	esac
}

#执行函数
main $1

