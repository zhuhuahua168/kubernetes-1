
docker启动：

    docker run -p 6379:6379 --name my-redis -d redis redis-server --appendonly yes --requirepass pass123


kubernetes中：

    kubectl create -f redis-rc.yaml


   The server is now ready to accept connections on port 6379


     kubectl create -f redis-svc.yaml

查看是否成功：

     kubectl get service


进入redis安装目录,测试是否成功，31379端口不行：

 redis-cli.exe -h 139.196.48.36 -p 30061 -a 密码



注：
1. 修改默认Service Port Range

Default 是30000-32767。 如果超出此范围，创建service时就会报错：


spec.ports[0].nodePort: Invalid value: 20001: provided port is not in the valid range

修改apiserver的配置文件：

    ========

    # Add your own!

    #KUBE_API_ARGS=""
    KUBE_API_ARGS="--service-node-port-range=20000-65535“    <--  建议最低端口号不要过小，防止与其他程序冲突

    ========

    重启apiserver，重新创建端口号20001的Service，验证Port Range是否修改成功。




参考资料：

[https://clusterhq.com/2016/02/11/kubernetes-redis-cluster/](https://clusterhq.com/2016/02/11/kubernetes-redis-cluster/)

[http://dockone.io/article/542](http://dockone.io/article/542)