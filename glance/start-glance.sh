#!/bin/bash

# usage: start-glance.sh <region name> [keystone region name]

set -ex

. credentials.sh

test -z $1 && exit 1
test -z $2 && exit 1
test -z $3 && exit 1

region_name=$1
db_cname=$2
keystone_master=$3 # container name
keystone="keystone_${region_name}"
registry_cname="glance_registry_${region_name}"
api_cname="glance_api_${region_name}"

echo "Starting Image service for region $region_name"

echo "   Starting glance-registry"
docker run -d \
    -e DEBUG=YES \
    -e DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
    -e GLANCE_DB_PASSWORD=$GLANCE_DB_PASSWORD \
    -e GLANCE_KEYSTONE_PASSWORD=$GLANCE_KEYSTONE_PASSWORD \
    --link $db_cname:db --link $keystone:keystone \
    --name $registry_cname \
    hafe/glance \
    /bin/glance-registry-start.sh > /dev/null

echo "   Starting glance-api"
docker run -d \
    -e DEBUG=YES \
    -e OS_USERNAME=$OS_ADMIN_USERNAME \
    -e OS_PASSWORD=$OS_ADMIN_PASSWORD \
    -e OS_REGION_NAME=Kista \
    -e GLANCE_DB_PASSWORD=$GLANCE_DB_PASSWORD -e REGION_NAME=$region_name \
    -e KEYSTONE_ADMIN_TOKEN=$KEYSTONE_ADMIN_TOKEN \
    -e GLANCE_KEYSTONE_PASSWORD=$GLANCE_KEYSTONE_PASSWORD \
    --link $db_cname:db --link $keystone_master:keystone_master --link $keystone:keystone \
    --link $registry_cname:glance_registry \
    --name $api_cname \
    hafe/glance \
    /bin/glance-api-start.sh > /dev/null

