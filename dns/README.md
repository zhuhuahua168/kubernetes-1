##下载镜像文件##

下载busybox:

    docker pull index.tenxcloud.com/google_containers/busybox:1.24
    docker tag index.tenxcloud.com/google_containers/busybox:1.24 gcr.io/google_containers/busybox:1.24

使用方法：kubectl exec -i -t busybox sh

    [root@localhost k8s]# kubectl exec -i -t busybox sh
    / # nslookup mysql-service
     Server:    10.254.0.10
     Address 1: 10.254.0.10 localhost

    Name:      mysql-service
    Address 1: 10.254.162.44
    / # nslookup mysql-service.default.kube.local
    Server:    10.254.0.10
    Address 1: 10.254.0.10

    Name:      mysql-service.default.kube.local
    Address 1: 10.254.162.44
    / # nslookup mysql-service.default.svc.kube.local
    Server:    10.254.0.10
    Address 1: 10.254.0.10

    Name:      mysql-service.default.svc.kube.local
    Address 1: 10.254.162.44

打上tag标签

exechealthz:

    docker tag 951a gcr.io/google_containers/exechealthz:1.0

etcd:

    docker tag index.tenxcloud.com/google_containers/etcd-amd64:2.2.1 gcr.io/google_containers/etcd-amd64:2.2.1

kube2sky:

    docker tag index.tenxcloud.com/google_containers/kube2sky:1.12 gcr.io/google_containers/kube2sky:1.12

skydns:

    docker tag index.tenxcloud.com/google_containers/skydns:2015-10-13-8c72f8c gcr.io/google_containers/skydns:2015-10-13-8c72f8c

##查看etcd容器中的域名信息
    docker exec -it ed61 sh
    /#etcdctl ls --recursive


##遇到的问题##
Q：kube2sky flag provided but not defined: -kube-master_url

A：
将skydns-rc.yaml中kube2sky:

    - name: kube2sky 
        image: gcr.io/google_containers/kube2sky:1.12
        args:
        # command= "/kube2sky"
        - --domain=mycluster.com
        - --kube-master-url=http://192.168.27.131:8080
        # --etcd-server=http://192.168.46.40:4001
        # --etcd-mutation-timeout=20

改成

    - name: kube2sky 
        image: gcr.io/google_containers/kube2sky:1.12
        #args:
        # command= "/kube2sky"
        #- --domain=mycluster.com
        #- --kube-master-url=http://192.168.27.131:8080
        # --etcd-server=http://192.168.46.40:4001
        # --etcd-mutation-timeout=20
        command:
        - /kube2sky
        - --kube_master_url=http://192.168.27.131:8080
        - -domain=mycluster.com

Q:skydns:falling back to default configuration, could not read from etcd: 100: Key not found

A:这个错误暂时可以忽略，转换。不能转换主要是busybox在centos下转换dns有点问题。但是可以在其他的pod中正常运行


Q:skydns: falling back to default configuration, could not read from etcd: 501: All the given peers are not reachable

A:node节点上的kubelet没有配置好，/etc/kubernetes/kubelet正常的配置应该为：

    # Add your own!
    KUBELET_ARGS="--cluster_dns=10.254.200.200 --cluster-domain=cluster.local"

之后重启：

    systemctl daemon-reload
    systemctl restart kubelet
