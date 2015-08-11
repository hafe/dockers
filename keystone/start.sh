#!/bin/bash

# Start script for keystone
# Configures keystone using environment variables

set -e

[[ $DEBUG ]] && set -x

role=$1

. /opt/kolla/kolla-common.sh

: ${DB_SERVICE_HOST:=$DB_PORT_3306_TCP_ADDR}
: ${DB_SERVICE_PORT:=3306}
: ${KEYSTONE_DB_NAME:=keystone}
: ${KEYSTONE_DB_USER:=keystone}

# Identity driver, ...
: ${DEFAULT_IDENTITY_DRIVER:=sql}
: ${SECOND_IDENTITY_DRIVER:=""}

# Token provider, driver, etc..
: ${TOKEN_PROVIDER:=uuid}
TOKEN_DRIVER=""
if [ "$TOKEN_PROVIDER" == "uuid" ]; then
    TOKEN_DRIVER="sql"
fi

. /opt/kolla/kolla-common.sh

check_required_vars DB_SERVICE_HOST MEMCACHED_PORT_11211_TCP_ADDR \
    KEYSTONE_ADMIN_TOKEN KEYSTONE_DB_PASSWORD DB_ROOT_PASSWORD

# lets wait for the DB to be available
wait_for 25 1 check_for_db

if [ "$role" == "master" ]; then
    echo "Setting up Keystone DB"
    mysql -h ${DB_SERVICE_HOST} -u root -p"${DB_ROOT_PASSWORD}" mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${KEYSTONE_DB_NAME};
GRANT ALL PRIVILEGES ON ${KEYSTONE_DB_NAME}.* TO
    '${KEYSTONE_DB_USER}'@'%' IDENTIFIED BY '${KEYSTONE_DB_PASSWORD}';
EOF
fi

# File path and name used by crudini tool
cfg=/etc/keystone/keystone.conf

# Token Configuration
echo "Configuring keystone.conf"
crudini --set $cfg \
    DEFAULT \
    admin_token \
    "${KEYSTONE_ADMIN_TOKEN}"

# Database Configuration
crudini --set $cfg \
    database \
    connection \
    "mysql://${KEYSTONE_DB_USER}:${KEYSTONE_DB_PASSWORD}@${DB_SERVICE_HOST}/${KEYSTONE_DB_NAME}"

# Default Identity driver
crudini --set $cfg identity driver keystone.identity.backends.${DEFAULT_IDENTITY_DRIVER}.Identity

# Assignment
crudini --set $cfg assignment driver keystone.assignment.backends.sql.Assignment

# Token Management
crudini --set $cfg \
    token \
    provider \
    keystone.token.providers."${TOKEN_PROVIDER}".Provider

if [ -n "$TOKEN_DRIVER" ]; then
    crudini --set $cfg \
        token \
        driver \
        keystone.token.persistence.backends."${TOKEN_DRIVER}".Token

    crudini --set $cfg \
        revoke \
        driver \
        keystone.contrib.revoke.backends."${TOKEN_DRIVER}".Revoke
fi

# Cache Configuration
crudini --set $cfg \
    cache \
    memcache_servers \
    "$MEMCACHED_PORT_11211_TCP_ADDR:11211"

if [ "$TOKEN_PROVIDER" == "fernet" ]; then
    test -d /etc/keystone/fernet-keys || exit 1
    crudini --set $cfg fernet_tokens max_active_keys 4
    crudini --set $cfg fernet_tokens key_repository /etc/keystone/fernet-keys

    test -f /etc/keystone/fernet-keys/0 ||
        keystone-manage fernet_setup --keystone-user $(id -u) \
            --keystone-group $(id -g)
    chmod 600 /etc/keystone/fernet-keys
fi

configure_ldap() {
    cfg=$1

    # server and credentials
    crudini --set $cfg ldap url ldap://${LDAP_PORT_389_TCP_ADDR}
    crudini --set $cfg ldap suffix $LDAP_DOMAIN
    crudini --set $cfg ldap use_dumb_member False
    crudini --set $cfg ldap allow_subtree_delete False
    crudini --set $cfg ldap user_id_attribute uid
    crudini --set $cfg ldap user_name_attribute uid

    # User and Groups OU
    crudini --set $cfg ldap user_tree_dn "ou=Users,$LDAP_DOMAIN"
    crudini --set $cfg ldap user_objectclass inetOrgPerson
    crudini --set $cfg ldap group_tree_dn "ou=Groups,$LDAP_DOMAIN"
    crudini --set $cfg ldap group_objectclass groupOfNames

    # read only
    crudini --set $cfg ldap user_allow_create False
    crudini --set $cfg ldap user_allow_update False
    crudini --set $cfg ldap user_allow_delete False
    crudini --set $cfg ldap group_allow_create False
    crudini --set $cfg ldap group_allow_update False
    crudini --set $cfg ldap group_allow_delete False

    cat $cfg
}

crudini --set $cfg identity domain_specific_drivers_enabled True

# LDAP Configuration
if [ "$SECOND_IDENTITY_DRIVER" == "ldap" ]; then
    crudini --set $cfg identity domain_specific_drivers_enabled True
    crudini --set $cfg identity domain_config_dir "/etc/keystone/domains"

    configure_ldap /etc/keystone/domains/keystone.acme.conf
fi

if [ "$DEFAULT_IDENTITY_DRIVER" == "ldap" ]; then
    configure_ldap /etc/keystone/keystone.conf
fi

if [ "$role" == "master" ]; then
    echo "Populating the identity service database..."
    keystone-manage db_sync
fi

echo "Starting keystone"
keystone-all --version
if [ -z $DEBUG ]; then
    exec keystone-all -v
else
    exec keystone-all -dv
fi

