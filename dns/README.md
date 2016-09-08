##老版本kube2dns+skydns+etcd版本的已迁移至zhg-study/dns中，本版本采用kubernets最新的kubedns模板代码生成的。自动生成方法见我的github项目中。现在我是采用手工替换的方法

###下面是2个kubeyaml模板

    skydns-rc.yaml.in
    skydns-svc.yaml.in

###生成之后的模板
    skydns-rc.yaml
    skydns-svc.yaml

###创建

    kubectl create -f skydns-svc.yaml
    
    kubectl create -f skydns-rc.yaml


###删除

    kubectl delete -f skydns-svc.yaml
    
    kubectl delete -f skydns-rc.yaml