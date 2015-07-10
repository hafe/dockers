#!/bin/bash

set  -e

test $# -eq 1 || (echo "error: region name missing"; exit 1)

region_name=$1
name=memcached_${region_name}

echo "starting container '$name'"
docker run -d --name $name memcached > /dev/null

