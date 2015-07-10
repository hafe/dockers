#!/bin/bash

set  -e

echo "starting slapd for domain $SLAPD_DOMAIN"
docker run -d --name slapd -e SLAPD_PASSWORD=$SLAPD_PASSWORD \
    -e SLAPD_DOMAIN=$SLAPD_DOMAIN dinkel/openldap > /dev/null

