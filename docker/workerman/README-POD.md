1.在pod定义文件中将推送的阿里云镜像修改下。

2.删除原来运行的pod

    cd /mnt/kubernetes/

	kubectl delete -f workerman-pod.yaml

3.上传本workerman-pod.yaml

创建：

   kubectl create -f workerman-pod.yaml

4.成功