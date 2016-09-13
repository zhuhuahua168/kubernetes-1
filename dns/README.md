##老版本kube2dns+skydns+etcd版本的已迁移至zhg-study/dns中。[查看老版本说明](https://github.com/zouhuigang/kubernetes/tree/master/zhg-study/dns)

###下面是2个kubeyaml模板，自动生成方法见我的github项目中。

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



Q:有些情况下是会提示不能创建目录的

A:把securityContext权限打开