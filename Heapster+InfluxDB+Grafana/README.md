##Kubernets监控 Heapster+InfluxDB+Grafana

###1.修改主机状态

查看主机状态：

    hostnamectl status

    hostnamectl --static set-hostname k8s-master
注意：你不必重启机器以激活永久主机名修改。上面的命令会立即修改内核主机名。注销并重新登入后在命令行提示来观察新的静态主机名。


###2.使用 OpenSSL 工具在 Master 服务器上创建一些证书和私钥相关的文件：

    [root@master ~]# openssl genrsa -out ca.key 2048

    [root@master ~]# openssl req -x509 -new -nodes -key ca.key -subj "/CN=master.k8s.com" -days 5000 -out ca.crt

    [root@master ~]# openssl genrsa -out server.key 2048
    [root@master ~]# cat /etc/hostname 
					 k8s-master

    [root@master ~]# openssl req -new -key server.key -subj "/CN=k8s-master" -out server.csr

    [root@master ~]# openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 5000

   


注意:

生成6个文件，ca.crt、ca.key、ca.srl、server.crt、server.csr、server.key复制至/var/run/kubernetes/，该目录已存在，无需创建.

    cp *.* /var/run/kubernetes/

在生成 server.csr 时 -subj 参数中 /CN 指定的名字需为 Master 的主机名。

另外，在生成 ca.crt 时 -subj 参数中 /CN 的名字最好与主机名不同，设为相同可能导致对普通 Master 的 HTTPS 访问认证失败。

###3.修改master中的apiserver配置文件：
    KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

    KUBE_API_ARGS="--client-ca-file=/var/run/kubernetes/ca.crt \
               --tls-private-key-file=/var/run/kubernetes/server.key \
               --tls-cert-file=/var/run/kubernetes/server.crt"
 
    ##注释
    #--client-ca-file：根证书文件
    #--tls-cert-file：服务端证书文件
    #--tls-private-key-file：服务端私钥文件
重启:
    
    systemctl restart kube-apiserver

###4.修改master中的controller-manager：

    KUBE_CONTROLLER_MANAGER_ARGS="--service-account-private-key-file=/var/run/kubernetes/apiserver.key \
     --root-ca-file=/var/run/kubernetes/ca.crt"
	或
    KUBE_CONTROLLER_MANAGER_ARGS="--service-account-private-key-file=/var/run/kubernetes/server.key \
                              --root-ca-file=/var/run/kubernetes/ca.crt"

重启:

    systemctl restart kube-controller-manager


5.在 kube-apiserver 服务成功启动后，系统会自动为每个命名空间创建一个 ServiceAccount 和一个 Secret（包含一个 ca.crt 和一个 token）

查看

    kubectl get serviceaccounts --all-namespaces


启动:

    kubectl create -f influxdb-service.yaml

    kubectl create -f heapster-service.yaml

    kubectl create -f grafana-service.yaml

    kubectl create -f influxdb-controller.yaml

    kubectl create -f heapster-controller.yaml

    kubectl create -f grafana-controller.yaml

删除:

    kubectl delete -f influxdb-service.yaml
    kubectl delete -f heapster-service.yaml
    kubectl delete -f grafana-service.yaml
    kubectl delete -f influxdb-controller.yaml
    kubectl delete -f heapster-controller.yaml
    kubectl delete -f grafana-controller.yaml
