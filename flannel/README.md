    
https://github.com/kubernetes/kubernetes/blob/v1.2.0-alpha.5/docs/getting-started-guides/fedora/flannel_multi_node_cluster.md


##node上配置flannel

1.安装

    yum install flannel -y

2.修改文件：

vi /etc/sysconfig/flanneld：

    # Flanneld configuration options

    # etcd url location.  Point this to the server where etcd runs
    #FLANNEL_ETCD="http://k8s-master:4001"
    FLANNEL_ETCD="http://k8s-master:2379"

    # etcd config key.  This is the configuration key that flannel queries
    # For address range assignment
    FLANNEL_ETCD_KEY="/coreos.com/network"

    # Any additional options that you want to pass
    #FLANNEL_OPTIONS=""

3.master:在etcd中写入flannel配置，每个node节点上的flannel将会从这个大的CIDR中随机分配一个不冲突的子网给docker使用：

    etcdctl  set /coreos.com/network/config '{"Network":"10.254.0.0/16"}'

按enter回出现

    {"Network":"10.254.0.0/16"}


4.master上的etcd配置文件/etc/etcd/etcd.conf,把localhost换成k8s-master 

    ETCD_LISTEN_CLIENT_URLS="http://k8s-master:2379"

    ETCD_ADVERTISE_CLIENT_URLS="http://k8s-master:2379"

然后重启动etcd
    
    systemctl start etcd
    systemctl enable etcd
    alias etcdctl='etcdctl --peers="http://k8s-master:2379"'
    etcdctl ls

5.node上停止docker服务

    systemctl stop docker

6.运行

    systemctl enable flanneld

    systemctl start flanneld

7.查看网段是否像这样：

    ip addr
    
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:16:3e:00:77:49 brd ff:ff:ff:ff:ff:ff
    inet 10.174.155.169/21 brd 10.174.159.255 scope global eth0
       valid_lft forever preferred_lft forever
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:16:3e:00:75:86 brd ff:ff:ff:ff:ff:ff
    inet 139.196.48.36/22 brd 139.196.51.255 scope global eth1
       valid_lft forever preferred_lft forever
    4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN 
    link/ether 02:42:67:2c:89:37 brd ff:ff:ff:ff:ff:ff
    inet 10.254.54.1/24 scope global docker0
       valid_lft forever preferred_lft forever
    9: flannel0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1472 qdisc pfifo_fast state UNKNOWN qlen 500
    link/none 
    inet 10.254.54.0/16 scope global flannel0
       valid_lft forever preferred_lft forever

flannel0：x.x.x.0 

docker0: x.x.x.1

8.完成，重启动docker

    systemctl start docker


参考文章：

http://blog.csdn.net/ylwh8679/article/details/52264370

If docker is already running, then stop docker, delete docker bridge (docker0), start flanneld and restart docker as follows. Another alternative is to just reboot the system (systemctl reboot).

    systemctl stop docker
    ip link delete docker0
    systemctl start flanneld
    systemctl start docker