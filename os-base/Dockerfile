FROM ubuntu:15.04
MAINTAINER hafe

RUN apt-get update && apt-get install -y \
    crudini \
    curl \
    ldap-utils \
    mysql-client \
    python-mysqldb \
    python-ceilometerclient \
    python-cinderclient \
    python-glanceclient \
    python-heatclient \
    python-keystoneclient \
    python-neutronclient \
    python-novaclient \
    python-swiftclient \
    python-openstackclient

# Common service packages (gathered from apt-get install printout)
RUN apt-get install -y \
    alembic \
    init-system-helpers libicu52 libxml2 libxslt1.1 \
    python-alembic python-amqp python-anyjson \
    python-enum34 python-ipaddr python-keystonemiddleware \
    python-oslo-concurrency python-oslo-context python-oslo-db python-oslo-log \
    python-oslo-messaging python-oslo-middleware python-oslo-policy \
    python-oslosphinx \
    python-passlib python-paste python-pastedeploy python-pastedeploy-tpl \
    python-pastescript \
    python-sqlalchemy python-sqlalchemy-ext python-sqlparse \
    python-routes python-tempita \
    python-testresources python-testscenarios python-testtools python-webob

RUN mkdir -p /opt/kolla
COPY service_hosts.sh /opt/kolla/service_hosts.sh
COPY kolla-common.sh /opt/kolla/kolla-common.sh
COPY crux.sh /opt/kolla/crux.sh

