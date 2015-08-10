# hafe/dockers

Instructions and tools to start a mini multi region cloud on a single host
using docker containers. The only available services are keystone and glance, 
working to some extent.

The (current) goal is just to be able prototype multi region cloud.

To follow these steps you probably need a fairly recent docker version like 1.7.

Short description:
------------------
* Human users are in a singleton (shared by all regions) LDAP server.
* OpenStack Kilo is used since containers use Ubuntu 15.04 as base and its OS packages.
* Some ugly patches applied to Keystone which will break soon, FIX!
* A mysql-5.6-galera cluster (3 containers) is started per region
* Keystone configured to use Fernet tokens
* mysql async master/slave replication between the master cluster and slave clusters
* Some reuse from the OpenStack kolla project, see ref below

Build container images
----------------------
    . build-all

Source credentials
------------------
    . credentials.sh

Cleanup and delete ALL existing containers & volumes
--------------------------------------------------------------------
    docker rm -fv $(docker ps -aq)

Start LDAP server and provision it:
-----------------------------------
    tools/start-slapd.sh
    sleep 2
    docker run -it --rm --link slapd:ldap -e SLAPD_PASSWORD=$SLAPD_PASSWORD \
      -v $PWD/resources/provision.ldif:/root/provision.ldif hafe/os-base
    ldapadd -x -D cn=admin,dc=acme,dc=org -w $SLAPD_PASSWORD -f /root/provision.ldif -h ldap
    ldapsearch -x -h $LDAP_PORT_389_TCP_ADDR -b dc=acme,dc=org
    exit

Create Fernet keys data container:
-----------------------------------------
    tools/start-keystone-fernet-keys.sh

Start master region 'Kista':
----------------------------
    tools/start-mysql-galera.sh Kista 10
    # wait until galera cluster is up and synced
    docker logs -f mysql-Kista-11

    tools/start-memcached.sh Kista
    tools/start-keystone-region-1.sh Kista mysql-Kista-11 master

    # create domain 'acme' and project 'demo'
    docker run -it --link keystone_Kista:keystone --rm hafe/openstack-client
    openstack domain create --description "acme LDAP domain" acme
    openstack project create --domain acme --description "Demo project" demo
    exit

    # Restart keystone after domain and project has been created
    # (cannot use 'docker restart' since IP changes)
    docker stop keystone_Kista
    docker rm keystone_Kista
    docker rm -f memcached_Kista
    tools/start-memcached.sh Kista
    tools/start-keystone-region-2.sh Kista mysql-Kista-11

    # Assign role 'user' role to group 'demo' in project 'demo'
    # Needs to be done after the keystone restart to reference the group in LDAP
    docker run -it --link keystone_Kista:keystone --rm hafe/openstack-client
    projid=$(openstack project show -f shell demo -c id | awk -F [=\"] '{print $3}')
    openstack role add --project $projid --group demo --group-domain acme user
    exit

    # Test Keystone API access for user 'admin'
    docker run -it --link keystone_Kista:keystone --rm hafe/openstack-client
    openstack project list --domain acme
    openstack region list
    openstack domain list
    openstack project list --long
    openstack user list --domain Default
    openstack user list --domain acme
    openstack user show john --domain acme
    openstack endpoint list
    openstack role list
    openstack role assignment list
    openstack group list --domain acme
    exit

    # Test Keystone API access for user 'john'
    docker run -it --link keystone_Kista:keystone --rm hafe/openstack-client
    export OS_USERNAME=john
    export OS_PASSWORD=john
    export OS_USER_DOMAIN_NAME=acme
    export OS_PROJECT_DOMAIN_NAME=acme
    export OS_PROJECT_NAME=demo
    openstack catalog list
    exit

    # Start glance
    tools/start-glance.sh Kista mysql-Kista-12 keystone_Kista

    # Test Glance API access for user 'admin'
    docker run -it --link keystone_Kista:keystone --rm hafe/openstack-client
    glance image-list
    exit

Start region "Solna":
----------------------
    # Start slave database cluster
    tools/start-mysql-galera.sh Solna 20
    # wait until galera cluster is up and synced

    # start replication of slave database server, see mysql-galera/README

    tools/start-memcached.sh Solna
    tools/start-keystone-region.sh Solna mysql-Solna-22
    tools/start-glance.sh Solna mysql-Solna-22 keystone_Kista

References with useful information:
---------------------------------
* http://dev.mysql.com/doc/refman/5.6/en/index.html
* http://galeracluster.com/documentation-webpages/
* http://severalnines.com/blog
* http://www.ibm.com/developerworks/cloud/library/cl-configure-keystone-ldap-and-active-directory/index.html
* http://docs.openstack.org/admin-guide-cloud/content/configuring-keystone-for-ldap-backend-identity.html
* https://github.com/stackforge/kolla
