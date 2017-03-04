
# anooc滚动更新

应用的滚动升级

当集群中的某个服务需要升级时，我们需要停止目前与该服务相关的所有Pod，然后重新拉取镜像并启动。如果集群规模比较大，则这个工作就变成了一个挑战，而且先全部停止然后逐步升级的方式会导致较长时间的服务不可用。Kubernetes提供了rolling-update（滚动升级）功能来解决上述问题。 


另一种方法是不使用配置文件，直接用kubectl rolling-update命令，加上–image参数指定新版镜像名称来完成Pod的滚动升级

     kubectl rolling-update golang-anooc --image=registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/golang-production-anooc:1.1


与使用配置文件的方式不同，执行的结果是旧的RC被删除，新的RC仍将使用旧的RC的名字。 



1.anooc部署,qa服务器

    cd /mnt-linux/kubernetes-go

2.更改rc中的镜像版本

    kubectl create -f go-rc.yaml

3.扩容

    kubectl scale rc golang-anooc --replicas=4


一步升级

    kubectl rolling-update golang-anooc --image=registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/golang-production-anooc:1.6.8


如1.2的想更新1.2的小幅度更新。

1.先更新到改动最小的版本

	kubectl rolling-update golang-anooc --image=registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/golang-production-anooc:1.1

当要更新一样版本的时候，如在运行1.2版本的，镜像只是小幅度改动。先把它回滚到之前的版本，如1.1,然后把镜像删除，重新升级1.2的

2.再删除之间运行的镜像

    docker rmi registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/golang-production-anooc:1.2

3.然后在升级1.2版本

	kubectl rolling-update golang-anooc --image=registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/golang-production-anooc:1.2