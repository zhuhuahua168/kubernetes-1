### k8s的新属性ingress 的使用方法


环境:

	CentOS 7.4 64位
	镜像:CentOS 7.4 64位



三种暴露服务的方式（不含直接暴露pod）：

	LoadBlancer Service 
	NodePort Service 
	Ingress 



### LoadBlancer

	LoadBlancer Service 是 kubernetes 深度结合云平台的一个组件；当使用 LoadBlancer Service 暴露服务时，实际上是通过向底层云平台申请创建一个负载均衡器来向外暴露服务；目前 LoadBlancer Service 支持的云平台已经相对完善，比如国外的 GCE、DigitalOcean，国内的 阿里云，私有云 Openstack 等等，由于 LoadBlancer Service 深度结合了云平台，所以只能在一些云平台上来使用


### NodePort

	NodePort Service 顾名思义，实质上就是通过在集群的每个 node 上暴露一个端口，然后将这个端口映射到某个具体的 service 来实现的，虽然每个 node 的端口有很多(0~65535)，但是由于安全性和易用性(服务多了就乱了，还有端口冲突问题)实际使用可能并不多


### Ingress

	Ingress 这个东西是 1.2 后才出现的，通过 Ingress 用户可以实现使用 nginx 等开源的反向代理负载均衡器实现对外暴露服务，以下详细说一下 Ingress，毕竟 traefik 用的就是 Ingress



### 使用

1.Ingress

最简单的:

	1: apiVersion: extensions/v1beta1
	2: kind: Ingress
	3: metadata:
	4:   name: test-ingress
	5: spec:
	6:   rules:
	7:   - http:
	8:       paths:
	9:       - path: /testpath
	10:        backend:
	11:           serviceName: test
	12:           servicePort: 80


###### 如果你没有配置Ingress controller就将其POST到API server不会有任何用处

说明：

	1-4行：跟Kubernetes的其他配置一样，ingress的配置也需要apiVersion，kind和metadata字段。配置文件的详细说明请查看部署应用, 配置容器和 使用resources.

	5-7行: Ingress spec 中包含配置一个loadbalancer或proxy server的所有信息。最重要的是，它包含了一个匹配所有入站请求的规则列表。目前ingress只支持http规则。

	8-9行：每条http规则包含以下信息：一个host配置项（比如for.bar.com，在这个例子中默认是*），path列表（比如：/testpath），每个path都关联一个backend(比如test:80)。在loadbalancer将流量转发到backend之前，所有的入站请求都要先匹配host和path。

	10-12行：正如 services doc中描述的那样，backend是一个service:port的组合。Ingress的流量被转发到它所匹配的backend。

	全局参数：为了简单起见，Ingress示例中没有全局参数，请参阅资源完整定义的api参考。 在所有请求都不能跟spec中的path匹配的情况下，请求被发送到Ingress controller的默认后端，可以指定全局缺省backend。

Ingress解决的是新的服务加入后，域名和服务的对应问题，基本上是一个ingress的对象，通过yaml进行创建和更新进行加载



2.Ingress Controllers

>Ingress Controllers 在k8s中，将以pod的形式运行,将监控后端的services，如果services变化了，将自动更新其新定义的转发规则。
>说白了，就是相当于一个nginx/haproxy，然后绑定80/443端口，将请求转发给对应的services。

Ingress Controller是将Ingress这种变化生成一段Nginx的配置，然后将这个配置通过Kubernetes API写到Nginx的Pod中，然后reload



### 镜像说明

	index.tenxcloud.com/google_containers/nginx-ingress-controller:0.8.3

	docker pull index.tenxcloud.com/google_containers/nginx-ingress:0.1






### 访问地址


	http://traefik-ui.local:8580/dashboard/#/


	curl -v 10.254.0.1:443


	iptables -P FORWARD ACCEPT

	systemctl stop kubelet
	systemctl stop docker
	iptables --flush
	iptables -tnat --flush
	systemctl start kubelet
	systemctl start docker
	
	The route problem can be solved by flush iptables.


删除证书：

	kubectl delete serviceaccount default
	kubectl delete serviceaccount --namespace=kube-system default



docker traefik:

	docker run -d -p 8081:8080 -p 81:80 \
	-v $PWD/traefik.toml:/etc/traefik/traefik.toml \
	-v /var/run/docker.sock:/var/run/docker.sock \
	traefik


### 问题汇总

Q1：搭建成功后，在本地设置好了hosts域名映射之后，访问域名发现报404 page not found,查看traefik log日志发现10.254.0.1:443不能访问.

A1:

	验证证书:

	curl --cacert /var/run/kubernetes/ca.crt -X GET https://10.254.0.1:443/api/v1/namespaces/default/pods   -v

	curl -v https://10.254.0.1:443
	centos7关闭selinux

	成功显示:
	[root@k8s-master-www ~]# curl -v 10.254.0.1:443
	* About to connect() to 10.254.0.1 port 443 (#0)
	*   Trying 10.254.0.1...
	* Connected to 10.254.0.1 (10.254.0.1) port 443 (#0)
	> GET / HTTP/1.1
	> User-Agent: curl/7.29.0
	> Host: 10.254.0.1:443
	> Accept: */*
	> 
	
	* Connection #0 to host 10.254.0.1 left intact


Q2:


	etcd：
		 error verifying flags, expected IP in URL for binding

A2：将http://k8s-master：2379地址改成http://0.0.0.0：2379

参考文档:

[http://blog.csdn.net/ximenghappy/article/details/60870557](http://blog.csdn.net/ximenghappy/article/details/60870557)

[https://traefik.io/](https://traefik.io/)

[https://www.kubernetes.org.cn/1237.html](https://www.kubernetes.org.cn/1237.html)

[https://www.kubernetes.org.cn/1885.html](https://www.kubernetes.org.cn/1885.html)

[https://blog.osones.com/en/kubernetes-traefik-and-lets-encrypt-at-scale.html](https://blog.osones.com/en/kubernetes-traefik-and-lets-encrypt-at-scale.html)

[https://crondev.com/kubernetes-nginx-ingress-controller/](https://crondev.com/kubernetes-nginx-ingress-controller/)

[https://helpcdn.aliyun.com/document_detail/53770.html](https://helpcdn.aliyun.com/document_detail/53770.html)

[https://github.com/ypelud/kubernetes_traefik](https://github.com/ypelud/kubernetes_traefik)

[https://docs.traefik.cn/user-guide/kubernetes](https://docs.traefik.cn/user-guide/kubernetes)

[https://www.cnblogs.com/chiwg/p/5556365.html](https://www.cnblogs.com/chiwg/p/5556365.html)