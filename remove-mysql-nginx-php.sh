#!/bin/bash
kubectl delete -f mysql-service.yaml &&
kubectl delete -f mysql-pod.yaml &&
kubectl delete -f nginx-phpfpm-service.yaml &&
kubectl delete -f nginx-phpfpm-pod.yaml
