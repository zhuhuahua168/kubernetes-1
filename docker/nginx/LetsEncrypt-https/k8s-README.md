### 为了让docker中的nginx用上https，同时解决自动续期的问题

>现规划如下,宿主机上安装自动生成https证书的软件并设置定时任务，2个月更新一次证书，然后把生成证书的目录挂载进docker,并设置docker中的nginx重新加载配置文件，不需要重启,把这一过程，写入shell脚本中，定时执行即可.

链接：[https://github.com/zouhuigang/scripts](https://github.com/zouhuigang/scripts)

宿主机安装脚本：

	  mkdir -p /etc/nginx/cert/ && cd /etc/nginx/cert/
	  wget https://raw.githubusercontent.com/xdtianyu/scripts/master/lets-encrypt/letsencrypt.conf
	
	  wget https://raw.githubusercontent.com/xdtianyu/scripts/master/lets-encrypt/letsencrypt.sh
	
	  chmod +x letsencrypt.sh

修改里面的配置文件或直接上传本项目的scripts里面的文件替换掉letsencrypt.sh letsencrypt.conf，然后运行脚本：

	./letsencrypt.sh letsencrypt.conf


执行过程中会自动生成需要的 key 文件。其中 ACCOUNT_KEY 为账户密钥， DOMAIN_KEY 为域名私钥， DOMAIN_DIR 为域名指向的目录，DOMAINS 为要签的域名列表， 需要 ECC 证书时取消 #ECC=TRUE 的注释，需要为 lighttpd 生成 pem 文件时，取消 #LIGHTTPD=TRUE 的注释。

结果如下：

	[root@k8s-master-www cert]# ./letsencrypt.sh letsencrypt.conf
	Generate account key...
	Generating RSA private key, 4096 bit long modulus
	....................................++
	....................................................................................................................................++
	e is 65537 (0x10001)
	Generate domain key...
	Generating RSA private key, 2048 bit long modulus
	........+++
	.....................................+++
	e is 65537 (0x10001)
	Generate CSR...privkey.csr
	Parsing account key...
	Parsing CSR...
	Registering account...
	Registered!
	Verifying www.xbaod.com...
	www.xbaod.com verified!
	Verifying xbaod.com...
	xbaod.com verified!
	Signing certificate...
	Certificate signed!
	New cert: fullchain.pem has been generated
	[root@k8s-master-www cert]# 


nfs共享配置文件：

	vi  /etc/exports
	/etc/nginx/cert *(rw,sync,no_root_squash,insecure)

	exportfs -rv 
    查看挂载的目录是否有被共享出来

滚动更新nginx版本

	kubectl rolling-update www.yyang.net.cn-rc-name-v1  -f nginx-phpfpm-rc-v2.yaml --update-period=10s


定时刷新：

	yum install -y jq #方面操作json

说明：

	#得到pod
	kubectl get pod --selector app=www.yyang.net.cn-pod-app,version=v2 --output=json

	kubectl get pod --selector app=www.yyang.net.cn-pod-app,version=v2 --output=json| jq -r '.items[] | select(.status.phase == "Running") | .metadata.name')

reload-nginx-https.sh

	chmod +x reload-nginx-https.sh 

	./reload-nginx-https.sh 


定时任务：

	crontab -e

每个月执行一次(正式环境)：

	0 0 1 * *  cd /etc/nginx/cert/ && ./reload-nginx-https.sh >> /etc/nginx/cert/lets-encrypt.log 2>&1

每10分钟执行一次(测试用,测试完成记得删除~~):

		*/10 * * * *  cd /etc/nginx/cert/ && ./reload-nginx-https.sh >> /etc/nginx/cert/lets-encrypt.log 2>&1


在浏览器查看证书具体时间
