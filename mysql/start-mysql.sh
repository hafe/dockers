#!/bin/bash -x

# startup a new database server

set -e

test $# -ne 2 && (echo "error: args missing"; exit 1)

cname=$1
server_id=$2

region_tmp_dir="$PWD/tmp/$cname"

create_server_conf() {
    filename=$1

    cat > $filename << EOF
[mysqld]
server_id=$server_id
report-host=$cname
report-port=3306

default_storage_engine=InnoDB
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

binlog_format=ROW
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1

# skip host cache with client info
skip-host-cache

# disable DNS host name lookups
skip-name-resolve

# GTID & binlog for master/slave replication
gtid_mode=ON 
log_bin=binlog
enforce-gtid-consistency=true
log-slave-updates=1
EOF
}

start_node() {
    role=$1

    server_cnf="server.cnf"
    server_cnf_file="$region_tmp_dir/server.cnf"
    create_server_conf $server_cnf_file

    echo "starting container '$cname'"
    docker run -d --name $cname \
        -e DEBUG=YES -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
        -v $server_cnf_file:/etc/mysql/conf.d/$server_cnf:ro \
        mysql:5.6 mysqld --replicate-do-db=keystone \
            --replicate-ignore-db=mysql > /dev/null
}

mkdir -p $region_tmp_dir

start_node

