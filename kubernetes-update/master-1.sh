#!/bin/bash
systemctl restart etcd
# secondly, start flanneld
systemctl restart flanneld
# then, start docker
systemctl restart docker
# start the main server of k8s master
nohup kube-apiserver --insecure-bind-address=0.0.0.0 --insecure-port=8080 --cors_allowed_origins=.* --etcd_servers=http://192.168.122.134:4001 --v=1 --logtostderr=false --log_dir=/var/log/k8s/apiserver --service-cluster-ip-range=192.100.0.0/16 &
nohup kube-controller-manager --master=192.168.122.134:8080 --enable-hostpath-provisioner=false --v=1 --logtostderr=false --log_dir=/var/log/k8s/controller-manager &
nohup kube-scheduler --master=192.168.122.134:8080 --v=1 --logtostderr=false --log_dir=/var/log/k8s/scheduler &

