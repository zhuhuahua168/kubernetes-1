# Deploy K8S Multi-Node Clusters

Using Docker to deploy.

## Pre-requires

1. Ubuntu 16.04+ or RHEL/CentOS 7.0+ or OS that supports systemd.

2. Make sure k8s master and workers can access each other by FQDN.

3. The docker-engine package should be installed(my test version is 1.11.2).


## Configuration

```
MASTER_IP=<the_master_ip_here>
K8S_VERSION=<your_k8s_version (e.g. 1.2.1)>
ETCD_VERSION=<your_etcd_version (e.g. 2.2.1)>
FLANNEL_VERSION=<your_flannel_version (e.g. 0.5.5)>
FLANNEL_IFACE=<flannel_interface (defaults to eth0)>
FLANNEL_IPMASQ=<flannel_ipmasq_flag (defaults to true)>
FLANNEL_NETWORK=<flannel_network CIDR>
```


## Deployment

1. Clone this repository on all your master and worker nodes.

2. Update the `config.conf` file according to your environment.

3. Run script `master.sh` on master node.

4. Run script `worker.sh` on worker nodes.


## Note

If your nodes can't access the Internet, you need to update the `systemd/http-proxy.conf` file to specify your proxy address, then put it to following location.

* /etc/systemd/system/docker.service.d/http-proxy.conf
* /etc/systemd/system/docker-base.service.d/http-proxy.conf

## Reference

<http://kubernetes.io/docs/getting-started-guides/docker-multinode/master/>
