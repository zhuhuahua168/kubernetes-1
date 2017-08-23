#!/bin/bash
nowtime=`date +%Y-%m-%d_%H.%M.%S`
echo ${nowtime}" sh runing letsencrypt.sh"
#source letsencrypt.sh letsencrypt.conf
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/letsencrypt.sh letsencrypt.conf
sleep 5

echo "Init nginx ..."
pod=
until [ -n "$pod" -a "$pod" != "null" ]; do
pod=$(kubectl get pod --selector=app=www.yyang.net.cn-pod-app --output=json | jq -r '.items[] | select(.status.phase == "Running") | .metadata.name')
echo "waiting for nginx pod..."$pod
sleep 10
done

kubectl exec $pod -- nginx -s reload
echo "Init nginx ... Done"


