### echo v3版本，支持https而且更改了端口

创建

[root@k8s-master-www ~]# kubectl create -f go-rc.yaml 


缩放：

	kubectl scale rc golang-anooc-rc-name-v1  --replicas=1

滚动升级:

	kubectl rolling-update golang-anooc-rc-name-v1  -f go-rc-v2.yaml --update-period=10s


访问：

	https://139.196.16.67:30020/


向haproxy中注册服务:

添加https名称：

	http://www.51tywy.com:8500

注册服务:

https:

	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
			  \"ID\": \"dev_https_group_sites_anooc_1\",
			  \"Name\": \"dev_https_group_sites_anooc\",
			  \"Tags\": [],
			  \"Address\": \"127.0.0.1\",
			  \"Port\": 30020
			}" > /dev/null


http:

删除之前的服务:

	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_group_sites4_1
	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_group_sites8_1

创建新的：

	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites4_1\",
		  \"Name\": \"dev_group_sites4\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30019
		}" > /dev/null

	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
			  \"ID\": \"dev_group_sites8_1\",
			  \"Name\": \"dev_group_sites8\",
			  \"Tags\": [],
			  \"Address\": \"127.0.0.1\",
			  \"Port\": 30019
			}" > /dev/null


刷新模板

	consul-template -config /data/cfg/consul/tmpl.json > consul-template.out 2>&1 &