#!/bin/bash

# script to start nodes in a galera cluster

set -eo pipefail

# set debug based on envvar
[[ $DEBUG ]] && set -x

DATADIR="/var/lib/mysql"
SOCKET="/var/run/mysqld/mysqld.sock"

die() {
    echo $1
    exit 1
}

set_mysql_creds() {
    test -z $DB_ROOT_PASSWORD && die "error: missing env var DB_ROOT_PASSWORD"

    # start mysql so we can configure basics
    mysqld --datadir=$DATADIR --user=mysql --skip-networking &

    for i in $(seq 30 -1 0); do
        [ -S "$SOCKET" ] && break
        echo 'MySQL init process in progress...'
        sleep 1
    done
    if [ $i = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi

    mysql -e "SET wsrep_on=OFF; DROP DATABASE IF EXISTS test;"
    mysql -e "SET wsrep_on=OFF; DELETE FROM mysql.user;"
    mysql -e "SET wsrep_on=OFF; CREATE USER 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
    mysql -e "SET wsrep_on=OFF; GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;"
    mysql -e "SET wsrep_on=OFF; CREATE USER 'wsrep_sst_user'@'%' IDENTIFIED BY 'wsrep_sst_pass';"
    mysql -e "SET wsrep_on=OFF; GRANT ALL ON *.* TO 'wsrep_sst_user'@'%';"
    mysql -e "SET wsrep_on=OFF; CREATE USER 'repl'@'%' IDENTIFIED BY 'replpass';"
    mysql -e "SET wsrep_on=OFF; GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';"

    mysqladmin shutdown
}

init() {
    if [ ! -d "$DATADIR/mysql" ]; then
        mkdir -p "$DATADIR"
        chown -R mysql:mysql $DATADIR
        mysql_install_db --datadir=$DATADIR --user=mysql --keep-my-cnf
    fi

    chown -R mysql:mysql $DATADIR
}

case "$1" in
    single)
        echo "starting mysql without clustering"
        init && set_mysql_creds
        exec mysqld --verbose
      	;;
    master)
        echo "Starting cluster master"
        init && set_mysql_creds
        echo "wsrep_cluster_address=gcomm://" >> /etc/mysql/my.cnf
        exec mysqld --verbose
        ;;
    node)
        echo "Starting cluster node"
        init && set_mysql_creds
        echo "wsrep_cluster_address=gcomm://mysql-master" >> /etc/mysql/my.cnf
        exec mysqld --verbose
        ;;
    *)
        echo "start <single|master|node> <master node ip>"
	esac

