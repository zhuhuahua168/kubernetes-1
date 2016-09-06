    
https://github.com/kubernetes/kubernetes/blob/v1.2.0-alpha.5/docs/getting-started-guides/fedora/flannel_multi_node_cluster.md

    # Flanneld configuration options

    # etcd url location.  Point this to the server where etcd runs
    FLANNEL_ETCD="http://master-ip:4001"

    # etcd config key.  This is the configuration key that flannel queries
    # For address range assignment
    FLANNEL_ETCD_KEY="/coreos.com/network"

    # Any additional options that you want to pass
    FLANNEL_OPTIONS=""


systemctl enable flanneld

systemctl start flanneld



If docker is already running, then stop docker, delete docker bridge (docker0), start flanneld and restart docker as follows. Another alternative is to just reboot the system (systemctl reboot).

    systemctl stop docker
    ip link delete docker0
    systemctl start flanneld
    systemctl start docker