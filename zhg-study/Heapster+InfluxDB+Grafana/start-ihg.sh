kubectl create -f influxdb-service.yaml &&
    kubectl create -f heapster-service.yaml &&
    kubectl create -f grafana-service.yaml &&
    kubectl create -f influxdb-controller.yaml &&
    kubectl create -f heapster-controller.yaml &&
    kubectl create -f grafana-controller.yaml
