#!/bin/bash

# startup a new galera cluster of 3 nodes (containers)

set -e

test $# -eq 2 || (echo "error: args missing"; exit 1)

region=$1
cluster_index=$2  # 10, 20, 30 etc

region_tmp_dir="$PWD/tmp/$region"

create_server_conf() {
    filename=$1
    server_id=$2
    cluster_name=$3

    cat > $filename << EOF
[mysqld]
server_id=$id
report-host=mysql-$cluster_name-$server_id
report-port=3306
wsrep_cluster_name=$cluster_name
EOF
}

start_node() {
    cid=$1
    role=$2
    link_opts=$3

    cname="mysql-$region-$cid"

    server_cnf="server-${cid}.cnf"
    server_cnf_file="$region_tmp_dir/$server_cnf"
    create_server_conf $server_cnf_file $cid $region 

    echo "starting container '$cname'"
    docker run -d --name $cname \
        $link_opts \
        -e DEBUG=YES -e DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
        -v $server_cnf_file:/etc/mysql/conf.d/$server_cnf:ro \
        hafe/mysql-galera /start.sh $role > /dev/null
}

mkdir -p $region_tmp_dir

index=1
let base_cid=$cluster_index+$index

let cid=$cluster_index+$index
start_node $cid master

let index=index+1
let cid=$cluster_index+$index
start_node $cid node "--link mysql-${region}-${base_cid}:mysql-master"

let index=index+1
let cid=$cluster_index+$index
start_node $cid node "--link mysql-${region}-${base_cid}:mysql-master"

