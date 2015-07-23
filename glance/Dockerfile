FROM hafe/os-base
MAINTAINER hafe

RUN sed -i 's/archive.ubuntu.com/ftp.acc.umu.se/g' /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y \
    glance && \
    rm -f /var/lib/glance/glance.sqlite

# Static configuration (dynamic in start script)
RUN crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name openstack && \
    crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance && \
    crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_plugin password && \
    crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_id default && \
    crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_id default && \
    crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name openstack && \
    crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance && \     
    crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone && \
    crudini --set /etc/glance/glance-api.conf DEFAULT default_store file && \
    crudini --set /etc/glance/glance-api.conf DEFAULT filesystem_store_datadir /var/lib/glance/images && \
    crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver noop && \
    crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name openstack && \
    crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance && \
    crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password && \
    crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default && \
    crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default && \
    crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name openstack && \
    crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance && \     
    crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone && \
    crudini --set /etc/glance/glance-registry.conf DEFAULT notification_driver noop

EXPOSE 9292 9191

COPY config-glance.sh /opt/kolla/config-glance.sh
COPY glance-api-start.sh /bin/
COPY glance-registry-start.sh /bin/

