#!/bin/bash

kubectl create -f mysql-service.yaml &&
kubectl create -f mysql-pod.yaml &&
kubectl create -f nginx-phpfpm-service.yaml &&
kubectl create -f nginx-phpfpm-pod.yaml
