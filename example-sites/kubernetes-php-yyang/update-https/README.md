### 更新阿里云正规https证书

	kubectl create -f nginx-phpfpm-rc.yaml

	kubectl create -f nginx-phpfpm-service.yaml


### 访问地址


	http://139.196.16.67:30017

	https://139.196.16.67:30018

此时还是会提示不受信任的证书,绑定域名之后，用域名浏览，就不会有这个问题了，注意图片和css文件地址也要用https



### 查看所有services

	http://www.51tywy.com:8500/v1/agent/services

	之前的端口是30003和30004


### 更新services

#### 更新https端口,30004->30018

删除之前端口：

	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_https_group_sites3_1

创建：

	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_https_group_sites3_1\",
		  \"Name\": \"dev_https_group_sites3\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30018
		}" > /dev/null



#### 更新http端口,30003->30017

删除之前端口：

	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_group_site_wishyoung_cn_1
	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_group_site_wishyoung_com_1
	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_group_sites_xbaod1:30003
	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_group_sites_xbaod2:30003
	curl 127.0.0.1:8500/v1/agent/service/deregister/dev_group_sites3_1


创建：


	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_site_wishyoung_cn_1\",
		  \"Name\": \"dev_group_site_wishyoung_cn\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30017
		}" > /dev/null


2：

	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_site_wishyoung_com_1\",
		  \"Name\": \"dev_group_site_wishyoung_com\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30017
		}" > /dev/null


3：

	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites_xbaod1:30003\",
		  \"Name\": \"dev_group_sites_xbaod1\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30017
		}" > /dev/null



4：dev_group_sites_xbaod2:30003


	curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites_xbaod2:30003\",
		  \"Name\": \"dev_group_sites_xbaod2\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30017
		}" > /dev/null


5：

		curl -sf -X PUT "http://127.0.0.1:8500/v1/agent/service/register" --data "{
		  \"ID\": \"dev_group_sites3_1\",
		  \"Name\": \"dev_group_sites3\",
		  \"Tags\": [],
		  \"Address\": \"127.0.0.1\",
		  \"Port\": 30017
		}" > /dev/null


在浏览器核对端口及ip无误后，刷新模板


	consul-template -config /data/cfg/consul/tmpl.json > consul-template.out 2>&1 &