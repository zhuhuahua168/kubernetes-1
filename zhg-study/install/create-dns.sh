#!/bin/bash

base_dir=$(cd $(dirname $0) && pwd)
. $base_dir/config.conf
. $base_dir/functions.sh

sed -e "s/{{ pillar\['dns_replicas'\] }}/${DNS_REPLICAS}/g;s/{{ pillar\['dns_domain'\] }}/${DNS_DOMAIN}/g;s/{{ pillar\['dns_server'\] }}/${DNS_SERVER_IP}/g" \
    $base_dir/skydns.yaml.in > $base_dir/skydns.yaml

kubectl get namespaces kube-system || kubectl create namespace kube-system

kubectl create -f $base_dir/skydns.yaml
