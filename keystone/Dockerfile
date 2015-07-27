FROM hafe/os-base
MAINTAINER hafe

RUN apt-get update && apt-get install -y \
        keystone \
        patch && \
    rm -f /var/lib/keystone/keystone.sqlite

# Static configuration of keystone (dynamic in start script)
RUN crudini --set /etc/keystone/keystone.conf token provider keystone.token.providers.uuid.Provider && \
    crudini --set /etc/keystone/keystone.conf token driver keystone.token.persistence.backends.sql.Token && \
    crudini --set /etc/keystone/keystone.conf revoke driver keystone.contrib.revoke.backends.sql.Revoke && \
    crudini --set /etc/keystone/keystone.conf cache enabled true && \
    crudini --set /etc/keystone/keystone.conf cache backend dogpile.cache.memcached && \
    rm -f /var/lib/keystone/keystone.db

# Keystone support of LDAP+Fernet has issues in Kilo, some fixes are available
# upstream so patch keystone, ugly? YES!
COPY patch.txt /
RUN cd /usr/lib/python2.7/dist-packages && patch -p1 < /patch.txt

EXPOSE 5000 35357

COPY start.sh /
COPY start-2.sh /
COPY post-start.sh /
CMD ["/start.sh"]
RUN mkdir -p /etc/keystone/domains
COPY keystone.acme.conf /etc/keystone/domains/
