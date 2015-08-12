#!/bin/bash

# two domains, SQL & LDAP

set -ex

. credentials.sh

test -z $1 && exit 1
test -z $2 && exit 1

region_name=$1
db_cname=$2
keystone_master=$3 # container name
db_name="keystone_${region_name}"
name="keystone_${region_name}"
memcached_cname="memcached_${region_name}"

echo "Starting keystone for region $region_name"
docker run -d \
    -e DEBUG=YES \
    -e DEFAULT_IDENTITY_DRIVER=sql \
    -e TOKEN_PROVIDER=fernet \
    -e SECOND_IDENTITY_DRIVER=ldap \
    -e LDAP_DOMAIN="dc=acme,dc=org" \
    -e DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
    -e KEYSTONE_ADMIN_TOKEN=$KEYSTONE_ADMIN_TOKEN \
    -e KEYSTONE_DB_PASSWORD=$KEYSTONE_DB_PASSWORD \
    --volumes-from keystone-fernet-keys \
    --link $db_cname:db --link $memcached_cname:memcached --link slapd:ldap \
    --name $name \
    hafe/keystone > /dev/null

echo "   Sleeping a while letting keystone start"
sleep 10

echo "   Creating endpoints"
docker run \
    --rm \
    -e OS_USERNAME=$OS_ADMIN_USERNAME \
    -e OS_PASSWORD=$OS_ADMIN_PASSWORD \
    -e REGION_NAME=$region_name \
    -e OS_TOKEN=$KEYSTONE_ADMIN_TOKEN \
    --link $name:keystone \
    --link $keystone_master:keystone_master \
    hafe/keystone /create-endpoints.sh > /dev/null

