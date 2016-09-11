systemctl start etcd &&
systemctl start kube-apiserver &&
systemctl start kube-controller-manager &&
systemctl start kube-scheduler &&
#node1
systemctl start kubelet &&
systemctl start kube-proxy &&
systemctl start docker &&
systemctl start flanneld
