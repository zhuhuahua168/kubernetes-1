kubectl delete -f influxdb-service.yaml &&
    kubectl delete -f heapster-service.yaml &&
    kubectl delete -f grafana-service.yaml &&
    kubectl delete -f influxdb-controller.yaml &&
    kubectl delete -f heapster-controller.yaml &&
    kubectl delete -f grafana-controller.yaml
