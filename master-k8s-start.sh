#!/bin/bash
#为启动脚本授予执行权限 chmod +x k8s_start.sh
#

for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler
do 
	systemctl start $SERVICES
	#systemctl restart $SERVICES		    
	#systemctl enable $SERVICES
	#systemctl status $SERVICES 
done