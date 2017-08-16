#!/bin/bash
setenforce 0

kubectl delete -f pxc-www.yaml

kubectl create -f pxc-www.yaml

