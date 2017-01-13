#下载升级二进制文件，解压
[root@k8s-master ~]# wget https://storage.googleapis.com/kubernetes-release/release/v1.3.4/kubernetes.tar.gz
[root@k8s-master ~]# tar zxvf kubernetes.tar.gz 
[root@k8s-master ~]# cd kubernetes
[root@k8s-master kubernetes]# tar zxvf server/kubernetes-server-linux-amd64.tar.gz
kubernetes/
kubernetes/LICENSES
kubernetes/kubernetes-src.tar.gz
kubernetes/server/
kubernetes/server/bin/
kubernetes/server/bin/federation-apiserver.docker_tag
kubernetes/server/bin/federation-controller-manager.docker_tag
kubernetes/server/bin/federation-apiserver.tar
kubernetes/server/bin/kube-proxy
kubernetes/server/bin/federation-apiserver
kubernetes/server/bin/kube-apiserver.tar
kubernetes/server/bin/kube-apiserver.docker_tag
kubernetes/server/bin/kubelet
kubernetes/server/bin/kube-proxy.docker_tag
kubernetes/server/bin/kube-controller-manager.tar
kubernetes/server/bin/kubectl
kubernetes/server/bin/kube-dns
kubernetes/server/bin/hyperkube
kubernetes/server/bin/kube-scheduler.tar
kubernetes/server/bin/kube-controller-manager.docker_tag
kubernetes/server/bin/federation-controller-manager
kubernetes/server/bin/kube-apiserver
kubernetes/server/bin/kube-proxy.tar
kubernetes/server/bin/kube-scheduler.docker_tag
kubernetes/server/bin/kubemark
kubernetes/server/bin/kube-scheduler
kubernetes/server/bin/federation-controller-manager.tar
kubernetes/server/bin/kube-controller-manager
kubernetes/addons/
[root@k8s-master kubernetes]# 

#停止master和node的kubernetes组件
[root@k8s-master kubernetes]# systemctl stop kube-apiserver kube-controller-manager kube-scheduler

[root@k8s-node01 ~]# systemctl stop docker kubelet  kube-proxy
[root@k8s-node02 ~]# systemctl stop docker kubelet  kube-proxy

#删除master和node主机/usr/bin下原kube开头的文件
[root@k8s-master kubernetes]# cd /usr/bin
[root@k8s-master bin]# ll kube*
-rwxr-xr-- 1 root kube 36687408 Jun 24 09:11 kube-apiserver
-rwxr-xr-x 2 root root 47977904 Jun 24 09:11 kube-controller-manager
-rwxr-xr-x 1 root root 47977904 Jun 24 09:11 kubectl
-rwxr-xr-x 3 root root 47977904 Jun 24 09:11 kubelet
-rwxr-xr-x 3 root root 47977904 Jun 24 09:11 kube-proxy
-rwxr-xr-x 2 root root 47977904 Jun 24 09:11 kube-scheduler
[root@k8s-master bin]# rm -rf kube*
[root@k8s-master bin]# ll kube*
ls: cannot access kube*: No such file or directory
[root@k8s-master bin]# 

[root@k8s-node01 bin]# ll kube*
-rwxr-xr-x 2 root root 47977904 Jun 24 09:11 kubectl
-rwxr-xr-x 2 root root 47977904 Jun 24 09:11 kubelet
-rwxr-xr-x 2 root root 47977904 Jun 24 09:11 kube-proxy
[root@k8s-node01 bin]# rm -rf kube*
[root@k8s-node01 bin]# ll kube*
ls: cannot access kube*: No such file or directory

#将刚才解压的kube开头的文件复制至/usr/bin目录
[root@k8s-master bin]# cd 
[root@k8s-master ~]# cd kubernetes
[root@k8s-master kubernetes]# cp kubernetes/server/bin/kube* /usr/bin/
[root@k8s-master kubernetes]# scp kubernetes/server/bin/kube* 192.168.12.175:/usr/bin/
[root@k8s-master kubernetes]# scp kubernetes/server/bin/kube* 192.168.12.176:/usr/bin/

#启动master和node各组件
[root@k8s-master kubernetes]# systemctl restart kube-apiserver kube-controller-manager kube-scheduler
[root@k8s-master kubernetes]# systemctl status kube-apiserver kube-controller-manager kube-scheduler

[root@k8s-node01 ~]# systemctl restart docker kubelet  kube-proxy
[root@k8s-node01 ~]# systemctl status docker kubelet  kube-proxy
[root@k8s-node02 ~]# systemctl restart docker kubelet  kube-proxy
[root@k8s-node02 ~]# systemctl status docker kubelet  kube-proxy

#升级后检查：
[root@k8s-master ~]# kubectl get nodes
NAME         STATUS    AGE
k8s-node01   Ready     5h
k8s-node02   Ready     5h
[root@k8s-master ~]# kubectl version
Client Version: version.Info{Major:"1", Minor:"3", GitVersion:"v1.3.4", GitCommit:"dd6b458ef8dbf24aff55795baa68f83383c9b3a9", GitTreeState:"clean", BuildDate:"2016-08-01T16:45:16Z", GoVersion:"go1.6.2", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"3", GitVersion:"v1.3.4", GitCommit:"dd6b458ef8dbf24aff55795baa68f83383c9b3a9", GitTreeState:"clean", BuildDate:"2016-08-01T16:38:31Z", GoVersion:"go1.6.2", Compiler:"gc", Platform:"linux/amd64"}

#运行容器
[root@k8s-master templates]# kubectl create -f nginx.yaml 
pod "nginx" created
[root@k8s-master templates]# kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
nginx     1/1       Running   0          8s