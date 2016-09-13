#!/bin/bash

base_dir=$(cd $(dirname $0) && pwd)
. $base_dir/config.conf
. $base_dir/functions.sh

start_docker_base
sleep 5
start_etcd
sleep 5
set_flannel_network
start_flannel
sleep 5
update_docker
sleep 5
start_k8s_master
