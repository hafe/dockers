# hafe/dockers

Instructions and tools to start a mini multi region cloud on a single host
using docker containers. The only available services are keystone and glance
working to some extent.

The (current) goal is just to be able prototype multi region cloud.

Short description:
------------------
* Human users are in a singleton (shared by all regions) LDAP server.
* OpenStack Kilo is used since containers use Ubuntu 15.04 as base and its OS packages.
* A mysql-5.6-galera cluster (3 containers) is started per region
* mysql async master/slave replication between the master cluster and slave clusters

Build container images
----------------------
    . build_all

Source credentials
------------------
    . credentials

Cleanup and delete all existing containers & volumes
--------------------------------------------------------------------
    docker rm -fv $(docker ps -aq | grep hafe)

Start LDAP server:
------------------
    tools/start-slapd.sh

Provision LDAP server:
----------------------
    docker run -it --rm --link slapd:ldap -e SLAPD_PASSWORD=$SLAPD_PASSWORD \
      -v $PWD/os-base/provision.ldif:/root/provision.ldif hafe/os-base
    ldapadd -x -D cn=admin,dc=acme,dc=org -w $SLAPD_PASSWORD -f /root/provision.ldif -h ldap
    ldapsearch -x -h $LDAP_PORT_389_TCP_ADDR -b dc=acme,dc=org
    exit

References with good information:
---------------------------------
* http://dev.mysql.com/doc/refman/5.6/en/index.html
* http://galeracluster.com/documentation-webpages/
* http://severalnines.com/blog
* http://www.ibm.com/developerworks/cloud/library/cl-configure-keystone-ldap-and-active-directory/index.html
* http://docs.openstack.org/admin-guide-cloud/content/configuring-keystone-for-ldap-backend-identity.html
