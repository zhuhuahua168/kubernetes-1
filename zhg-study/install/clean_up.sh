#!/bin/bash

base_dir=$(cd $(dirname $0) && pwd)
. $base_dir/config.conf
. $base_dir/functions.sh

clean_up_containers
# clean_up_images
stop_services
# clean_up_files
clean_up_bridge
