#!/bin/bash

# idempotent keystone operations

crux_service() {
    openstack service show $1 &> /dev/null || openstack service create \
        --description "$3" --name "$1" "$2" > /dev/null
}

crux_endpoint() {
    region=$1
    name=$2
    interface=$3
    url=$4

    endpoint_id=$(openstack endpoint list | grep $region | grep $name | \
        grep $interface | awk '{print $2}')

    if [ -z $endpoint_id ]; then
        openstack endpoint create --region $region $name $interface "$url"
    else
        openstack endpoint set --url "$url" $endpoint_id
    fi
}

crux_role() {
    openstack role create --or-show $1 > /dev/null
}

crux_project() {
    openstack project create --or-show --domain $OS_PROJECT_DOMAIN_NAME --description "$1" "$2" > /dev/null
}

crux_user() {
    openstack user create --or-show --domain $OS_PROJECT_DOMAIN_NAME --password "$1" "$2"
}

crux_role_add() {
    project=$1
    user=$2
    role=$3

    # with domain enabled, work on IDs instead of names, because?
    projid=$(openstack project show -f shell $project -c id | awk -F [=\"] '{print $3}')
    userid=$(openstack user show --domain $OS_PROJECT_DOMAIN_NAME -f shell $user -c id | awk -F [=\"] '{print $3}')

    # this is stupid but the command always return zero
    exist=$(openstack role assignment list --project $projid --user $userid --role $role | wc -l)
    if [ $exist -eq 1 ]; then
        openstack role add --project $projid --user $userid $role
    fi
}

