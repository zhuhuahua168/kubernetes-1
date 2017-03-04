#!/bin/bash
#为启动脚本授予执行权限 chmod +x server-restart.sh
#生成6个证书
#删除证书文件 rm -rf ca.* && rm -rf server.*
cd ~
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=master.k8s.com" -days 5000 -out ca.crt
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=k8s-master-www" -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 5000
#复制证书到指定目录
cp *.* /var/run/kubernetes/
#重启动服务
for SERVICES in etcd docker kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy haproxy
do 
#	systemctl start $SERVICES
	systemctl restart $SERVICES		    
	#systemctl enable $SERVICES
	systemctl status $SERVICES 
done
docker start f07719612b76
consul agent -server -config-dir=/config -bootstrap -bind=139.196.16.67 &
