function start_docker_base() {
    cp $base_dir/systemd/docker-base.service /etc/systemd/system
    cp $base_dir/systemd/docker-base.socket /etc/systemd/system
    cp $base_dir/docker-base /usr/local/bin
    systemctl daemon-reload
    systemctl start docker-base.service
    systemctl enable docker-base.service
}

function start_etcd() {
    docker-base run -d --name=etcd -v /usr/share/ca-certificates/:/etc/ssl/certs --net=host \
        quay.io/coreos/etcd -name etcd0 -advertise-client-urls http://${MASTER_IP}:2379,http://${MASTER_IP}:4001 \
        -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 -initial-advertise-peer-urls http://${MASTER_IP}:2380 \
        -listen-peer-urls http://0.0.0.0:2380  -initial-cluster-token etcd-cluster-1  -initial-cluster etcd0=http://${MASTER_IP}:2380 -initial-cluster-state new
}

function set_flannel_network() {
    docker-base exec etcd /etcdctl set /coreos.com/network/config "{ \"Network\": \"$FLANNEL_NETWORK\" }"
}

function start_flannel() {
    docker-base run -d --name=flannel --net=host --privileged \
        -v /dev/net:/dev/net quay.io/coreos/flannel:${FLANNEL_VERSION} \
        /opt/bin/flanneld --ip-masq=${FLANNEL_IPMASQ} --iface=${FLANNEL_IFACE} --etcd-endpoints=http://${MASTER_IP}:4001
}

function update_docker() {
    systemctl stop docker
    ip link show docker0 && ip link set dev docker0 down
    ip link show docker0 && ip link del docker0
    docker-base exec flannel cat /run/flannel/subnet.env > /tmp/flannel.env
    . /tmp/flannel.env
    mkdir -p /etc/systemd/system/docker.service.d
    cat <<-EOF > /etc/systemd/system/docker.service.d/flannel.conf
	[Service]
	ExecStart=
	ExecStart=/usr/bin/docker daemon -H fd:// --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}
	EOF
	rm -f /tmp/flannel.env
    systemctl daemon-reload
    systemctl start docker
    systemctl enable docker
}

function start_k8s_master() {
    docker run -d \
        --volume=/:/rootfs:ro \
        --volume=/sys:/sys:ro \
        --volume=/var/lib/docker/:/var/lib/docker:rw \
        --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
        --volume=/var/run:/var/run:rw \
        --net=host \
        --privileged=true \
        --pid=host \
        gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
        /hyperkube kubelet \
            --allow-privileged=true \
            --api-servers=http://localhost:8080 \
            --v=2 \
            --address=0.0.0.0 \
            --enable-server \
            --hostname-override=127.0.0.1 \
            --config=/etc/kubernetes/manifests-multi \
            --containerized \
            --cluster-dns=${DNS_SERVER_IP} \
            --cluster-domain=${DNS_DOMAIN}
}

function start_k8s_worker() {
    docker run \
        --volume=/:/rootfs:ro \
        --volume=/sys:/sys:ro \
        --volume=/dev:/dev \
        --volume=/var/lib/docker/:/var/lib/docker:rw \
        --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
        --volume=/var/run:/var/run:rw \
        --net=host \
        --privileged=true \
        --pid=host \
        -d \
        gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
        /hyperkube kubelet \
            --allow-privileged=true \
            --api-servers=http://${MASTER_IP}:8080 \
            --v=2 \
            --address=0.0.0.0 \
            --enable-server \
            --containerized \
            --cluster-dns=${DNS_SERVER_IP} \
            --cluster-domain=${DNS_DOMAIN}
}

function start_service_proxy() {
    docker run -d \
        --net=host \
        --privileged \
        gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
        /hyperkube proxy \
            --master=http://${MASTER_IP}:8080 \
            --v=2
}

function clean_up_containers() {
    docker stop $(docker ps -q)
    docker rm $(docker ps -a -q)
    docker-base stop $(docker-base ps -q)
    docker-base rm $(docker-base ps -a -q)
}

function clean_up_images() {
    docker rmi $(docker images -q)
    docker-base rmi $(docker-base images -q)
}

function stop_services() {
    systemctl stop docker docker-base
    systemctl disable docker docker-base
}

function clean_up_files() {
   rm -rf /etc/systemd/system/docker-base.service \
          /etc/systemd/system/docker-base.service.d \
          /etc/systemd/system/docker-base.socket \
          /usr/local/bin/docker-base \
          /etc/systemd/system/docker.service.d \
          /var/lib/docker-base \
          /var/run/docker-base*
   systemctl daemon-reload
}

function clean_up_bridge() {
    ip link show docker0 && ip link set dev docker0 down
    ip link show docker0 && ip link del docker0
}
