### Let's Encrypt 生成免费https证书，有效期90天，需要动态更新


1.验证域名

	http://www.xbaod.com/.well-known/acme-challenge/JmPKAiwxJX24XLmXz0ZT76zV80CaBYQyPn0QXY_dBok

将JmPKAiwxJX24XLmXz0ZT76zV80CaBYQyPn0QXY_dBok这个文件，上传到网站根目录就行，因为在nginx中配置了重定向,然后浏览器访问

	http://www.xbaod.com/.well-known/acme-challenge/JmPKAiwxJX24XLmXz0ZT76zV80CaBYQyPn0QXY_dBok

即可下载下来


### 构建新版https

	 cd /d/www/github/kubernetes/docker/nginx/LetsEncrypt-https

	 docker build -t  registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/nginx_51tywy:v1.0.2 .

### 推送至阿里云

	docker push registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/nginx_51tywy:v1.0.2


### 滚动升级（针对rc）

	#kubectl rolling-update nginx-phpfpm-yyang  --image=registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/golang-production-anooc:v1.0.1

	kubectl rolling-update www.yyang.net.cn-rc-name -f nginx-phpfpm-rc-v2.yaml

	#kubectl rolling-update my-web-v1 -f my-web-v2-rc.yaml --update-period=10s


如果冲突了，可以直接创建，然后把原来的删除掉

	kubectl create -f nginx-phpfpm-rc-v2.yaml
	kubectl delete -f nginx-phpfpm-rc.yaml ##发现会保错，删除不掉，所以还是手动删除rc或者加参数  --cascade=false
	kubectl delete rc  www.yyang.net.cn-rc-name --cascade=false
	


### 升级查看

[https://github.com/zouhuigang/kubernetes/tree/master/example-sites/kubernetes-php-yyang/update-https](https://github.com/zouhuigang/kubernetes/tree/master/example-sites/kubernetes-php-yyang/update-https)

[http://blog.csdn.net/shenshouer/article/details/49156299](http://blog.csdn.net/shenshouer/article/details/49156299)

	
