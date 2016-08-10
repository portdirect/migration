#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=api
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg cfg_api_paste cfg_vassals BARBICAN_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg DEFAULT bind_host "0.0.0.0"
crudini --set $cfg DEFAULT bind_port "9311"
crudini --set $cfg DEFAULT host_href "https://${BARBICAN_API_SERVICE_HOST}/"



crudini --set $cfg_api_paste pipeline:barbican_api pipeline "keystone_authtoken context apiapp"

crudini --set $cfg_vassals uwsgi socket ":9311"
crudini --set $cfg_vassals uwsgi protocol "https"
crudini --set $cfg_vassals uwsgi paste "config:${cfg_api_paste}"
crudini --set $cfg_vassals uwsgi buffer-size "65535"
