##搭建kubernetes环境
node1： 139.196.16.67(外网地址）
        10.174.113.12(内网地址)

master: 139.196.48.36(外网地址）
        10.174.155.169(内网地址)



##master:

     systemctl disable firewalld

     systemctl stop firewalld

     yum -y install kubernetes etcd


增加host名字：

vi /etc/hosts

    10.174.155.169 k8s-master
    10.174.113.12  k8s-node1


编辑vim /etc/kubernetes/config:

    ###
    # kubernetes system config
    #
    # The following values are used to configure various aspects of all
    # kubernetes services, including
    #
    #   kube-apiserver.service
    #   kube-controller-manager.service
    #   kube-scheduler.service
    #   kubelet.service
    #   kube-proxy.service
    # logging to stderr means we get it in the systemd journal
    KUBE_LOGTOSTDERR="--logtostderr=true"

    # journal message level, 0 is debug
    KUBE_LOG_LEVEL="--v=0"

    # Should this cluster be allowed to run privileged docker containers
    KUBE_ALLOW_PRIV="--allow-privileged=false"

    # How the controller-manager, scheduler, and proxy find the apiserver
    KUBE_MASTER="--master=http://k8s-master:8080"
    KUBE_ETCD_SERVERS="--etcd_servers=http://k8s-master:4001"

编辑vim /etc/kubernetes/apiserver:

    ###
    # kubernetes system config
    #
    # The following values are used to configure the kube-apiserver
    #

    # The address on the local server to listen to.
    KUBE_API_ADDRESS="--insecure-bind-address=127.0.0.1"

    # The port on the local server to listen on.
    # KUBE_API_PORT="--port=8080"

    # Port minions listen on
    KUBELET_PORT="--kubelet-port=10250"

    # Comma separated list of nodes in the etcd cluster
    KUBE_ETCD_SERVERS="--etcd-servers=http://k8s-master:2379"

    # Address range to use for services
    KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

    # default admission control policies
    KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"

    # Add your own!
    KUBE_API_ARGS=""
    KUBE_API_ADDRESS="--address=0.0.0.0"
    KUBE_API_PORT="--port=8080"

启动：

systemctl start etcd

systemctl start kube-apiserver

systemctl start kube-controller-manager 

systemctl start kube-scheduler



##node1
     systemctl disable firewalld

     systemctl stop firewalld

     yum -y install kubernetes etcd


增加host名字：

vi /etc/hosts

    10.174.155.169 k8s-master
    10.174.113.12  k8s-node1


编辑vim /etc/kubernetes/config:

    ###
    # kubernetes system config
    #
    # The following values are used to configure various aspects of all
    # kubernetes services, including
    #
    #   kube-apiserver.service
    #   kube-controller-manager.service
    #   kube-scheduler.service
    #   kubelet.service
    #   kube-proxy.service
    # logging to stderr means we get it in the systemd journal
    KUBE_LOGTOSTDERR="--logtostderr=true"

    # journal message level, 0 is debug
    KUBE_LOG_LEVEL="--v=0"

    # Should this cluster be allowed to run privileged docker containers
    KUBE_ALLOW_PRIV="--allow-privileged=false"

    # How the controller-manager, scheduler, and proxy find the apiserver
    KUBE_MASTER="--master=http://k8s-master:8080"
    KUBE_ETCD_SERVERS="--etcd_servers=http://k8s-master:4001"


 vim /etc/kubernetes/kubelet：

    ###
    # kubernetes kubelet (minion) config

    # The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
    KUBELET_ADDRESS="--address=0.0.0.0"

    # The port for the info server to serve on
    KUBELET_PORT="--port=10250"

    # You may leave this blank to use the actual hostname
    KUBELET_HOSTNAME="--hostname-override=k8s-node1"

    # location of the api-server
    KUBELET_API_SERVER="--api-servers=http://k8s-master:8080"

    # pod infrastructure container
    KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"

    # Add your own!
    KUBELET_ARGS=""

启动：

    systemctl enable kube-proxy kubelet docker


    systemctl restart kube-proxy kubelet docker



 vim /etc/sysconfig/docker:

    INSECURE_REGISTRY='--insecure-registry gcr.io'



##下载docker pause

docker pull registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/pause

docker tag registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/pause gcr.io/google_containers/pause:0.8.0


##创建kubernetes-dashboard面板下载镜像:

下载镜像：

    docker pull index.tenxcloud.com/google_containers/kubernetes-dashboard-amd64:v1.1.1

打上标签：

    docker tag index.tenxcloud.com/google_containers/kubernetes-dashboard-amd64:v1.1.1 registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/kubernetes-dashboard-amd64:v1.1.1

推送到远程仓库：

    docker push registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/kubernetes-dashboard-amd64:v1.1.1


1.修改配置文件kube-dashboard-rc.yaml

 apiserver-host=http://139.196.48.36:8080  不能用k8s-master:8080

2.运行之后，访问地址：
http：//masterip:8080/ui


##搭建flanneld请查看/flannel

##搭建dns

##安装Heapster+InfluxDB+Grafana



问题：

Q:apiserver启动错误代码code:255 main-pid:xxxx

A：重启动reboot










    

