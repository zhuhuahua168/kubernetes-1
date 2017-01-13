### 设置健值

	etcdctl set key value


### 创建目录


	etcdctl mkdir /zouhuigang


### 在目录下设置值

	 etcdctl set /zouhuigang/sex man


### 远程设置目录中的值

	curl -L -X PUT http://127.0.0.1:2379/v2/keys/zouhuigang/sex -d value="new:1111"
	
	curl -L -X PUT http://192.168.122.135:2379/v2/keys/zouhuigang/sex -d value="new:1111"

	127.0.0.1如不能访问，可使用ip。192.168.122.135


### 查看目录

	etcdctl ls /zouhuigang

	可在另外一台服务器上远程访问：curl -L http://192.168.122.135:2379/v2/keys/zouhuigang


### 监视目录

>此目录有变化时，如新建，更新，删除，过期，监视者将得到通知


 	etcdctl watch --recursive /zouhuigang

	远程操作：

	curl -L http://127.0.0.1:2379/v2/keys/zouhuigang?wait=true\&recursive=true


再在另外的shell上操作：

     etcdctl set /zouhuigang/container2 localhost:2222


### 读取目录中的值


	etcdctl get /zouhuigang/age


### 修改值

	etcdctl update /zouhuigang/age 25

### 删除值

	etcdctl rm /zouhuigang/age

### 查看错误

	etcdctl --debug member list

### 问题



    Error from server: client: etcd cluster is unavailable or misconfigured


ETCDCTL_ENDPOINT=http://k8s-master:2379 etcdctl get /coreos.com/network/config

http://blog.csdn.net/linshenyuan1213/article/details/53304276

https://github.com/coreos/flannel/issues/343


/usr/bin/etcdctl --cert-file=/etc/ssl/etcd/client.crt --key-file=/etc/ssl/etcd/client.key --ca-file=/etc/ssl/etcd/ca.crt --endpoint=https://127.0.0.1:2379 set /coreos.com/network/config '{"Network": "10.244.0.0/16"}'
