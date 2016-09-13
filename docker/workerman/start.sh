#!/bin/bash

echo "workerman starting"

cd /workerman-todpole \
#php start.php stop \
php start.php start -d

if [ $? -eq 0 ];then
    echo "workerman success!!"
else
    echo "workerman fail"
fi
