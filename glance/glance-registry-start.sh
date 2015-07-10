#!/bin/bash

set -e

[[ $DEBUG ]] && set -x

export GLANCE_DB_NAME=glance

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-glance.sh

check_required_vars GLANCE_DB_USER GLANCE_DB_PASSWORD \
    DB_ROOT_PASSWORD DB_SERVICE_HOST

# lets wait for the DB server to be available
wait_for 25 1 check_for_db

: ${DB_USER:=admin}

echo "Creating the glance database ..."
mysql -h ${DB_SERVICE_HOST} -u root -p${DB_ROOT_PASSWORD} mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${GLANCE_DB_NAME} DEFAULT CHARACTER SET utf8;
GRANT ALL PRIVILEGES ON ${GLANCE_DB_NAME}.* TO
       '${GLANCE_DB_USER}'@'%' IDENTIFIED BY '${GLANCE_DB_PASSWORD}'
EOF

echo "Populating the glance database ..."
glance-manage db_sync

crudini --set /etc/glance/glance-registry-paste.ini \
    "filter:authtoken" \
    identity_uri \
    "http://$KEYSTONE_PORT_35357_TCP_ADDR:35357"

crudini --set /etc/glance/glance-registry-paste.ini \
    "filter:authtoken" \
    admin_user \
    $GLANCE_KEYSTONE_USER

crudini --set /etc/glance/glance-registry-paste.ini \
    "filter:authtoken" \
    admin_password \
    $GLANCE_KEYSTONE_PASSWORD

crudini --set /etc/glance/glance-registry-paste.ini \
    "filter:authtoken" \
    admin_tenant_name \
    service

echo "Starting glance-registry"
glance-registry --version
if [ -z $DEBUG ]; then
    exec glance-registry -v
else
    exec glance-registry -dv
fi

