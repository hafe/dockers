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
* Keystone image use git repo master branch to get latest fixes
* A mysql-5.6 database server is started per region
* Keystone configured to use Fernet tokens
* mysql master/slave replication between the master DB server and slave DB server(s)
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
    keystone/start-keystone-fernet-keys.sh

Start master region 'Kista':
----------------------------
    mysql/start-mysql.sh mysql-Kista 10
    # wait until database server is up
    docker logs -f mysql-Kista

    tools/start-memcached.sh Kista
    keystone/start-keystone-region-1.sh Kista mysql-Kista master

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
    keystone/start-keystone-region-2.sh Kista mysql-Kista

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
    glance/start-glance.sh Kista mysql-Kista keystone_Kista

    # Test Glance API access for user 'admin'
    docker run -it --link keystone_Kista:keystone --rm hafe/openstack-client
    glance image-list
    exit

Start region "Solna":
----------------------
    mysql/start-mysql.sh mysql-Solna 20
    # wait until database server is up
    docker logs -f mysql-Solna

    # start replication of slave database server (also  see mysql/README)
    masterip=$(docker inspect -f "{{.NetworkSettings.IPAddress}}" mysql-Kista)
    docker exec -it mysql-Solna env MASTER_IP=$masterip bash
    mysql -pdbroot -e "CHANGE MASTER TO MASTER_HOST='$MASTER_IP', MASTER_PORT=3306, MASTER_AUTO_POSITION=1;"
    mysql -pdbroot -e "START SLAVE USER='repl' PASSWORD='replpass';"
    exit

    docker exec -it mysql-Solna mysql -pdbroot keystone -e "select * from domain;"

    tools/start-memcached.sh Solna
    keystone/start-keystone-slave.sh Solna mysql-Solna keystone_Kista

    glance/start-glance.sh Solna mysql-Solna keystone_Kista

Test Image API access in different regions:
---------------------------------------------
    docker run -it --link keystone_Kista:keystone --rm hafe/openstack-client
    export OS_USERNAME=john
    export OS_PASSWORD=john
    export OS_USER_DOMAIN_NAME=acme
    export OS_PROJECT_DOMAIN_NAME=acme
    export OS_PROJECT_NAME=demo
    export OS_IMAGE_API_VERSION=2
    glance --os-region-name Kista image-list
    glance --os-region-name Solna image-list
    exit

References with useful information:
---------------------------------
* http://dev.mysql.com/doc/refman/5.6/en/index.html
* http://galeracluster.com/documentation-webpages/
* http://severalnines.com/blog
* http://www.ibm.com/developerworks/cloud/library/cl-configure-keystone-ldap-and-active-directory/index.html
* http://docs.openstack.org/admin-guide-cloud/content/configuring-keystone-for-ldap-backend-identity.html
* https://github.com/stackforge/kolla
