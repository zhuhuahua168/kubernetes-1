### 阿里云免费https证书，一年有效


### 构建新版https

	 cd /d/www/github/kubernetes/docker/nginx/aliyun-https

	 sudo docker build -t  registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/nginx_51tywy:v1.0.1 .

### 推送至阿里云

	docker push registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/nginx_51tywy:v1.0.1


### 滚动升级（针对rc）

	#kubectl rolling-update nginx-phpfpm-yyang  --image=registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/golang-production-anooc:v1.0.1


### 升级查看

[https://github.com/zouhuigang/kubernetes/tree/master/example-sites/kubernetes-php-yyang/update-https](https://github.com/zouhuigang/kubernetes/tree/master/example-sites/kubernetes-php-yyang/update-https)
