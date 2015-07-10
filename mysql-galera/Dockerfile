# This file creates an image with mysql galera cluster

FROM ubuntu:trusty

RUN groupadd -r mysql && useradd -r -g mysql mysql

# See http://galeracluster.com/documentation-webpages/installmysql.html
RUN apt-get update && \
    apt-get install -yq software-properties-common && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv BC19DDBA && \
    add-apt-repository 'deb http://releases.galeracluster.com/ubuntu trusty main'

RUN { \
		echo mysql-community-server mysql-community-server/data-dir select ''; \
		echo mysql-community-server mysql-community-server/root-pass password ''; \
		echo mysql-community-server mysql-community-server/re-root-pass password ''; \
		echo mysql-community-server mysql-community-server/remove-test-db select false; \
	} | debconf-set-selections && \
    apt-get update && \
    apt-get install -yq \
	galera-3 \
	galera-arbitrator-3 \
	mysql-utilities \
	mysql-wsrep-5.6 && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/mysql && \
    mkdir -p /var/lib/mysql

# copy file to a location where mysql_install_db can find it
RUN cp /usr/share/doc/mysql-wsrep-server-5.6/examples/my-default.cnf \
    /usr/share/mysql/my-default.cnf

COPY ./my.cnf /etc/mysql/my.cnf
COPY ./start.sh /start.sh
CMD ["/start.sh"]

VOLUME ["/var/lib/mysql]

EXPOSE 3306 4444 4567 4568

