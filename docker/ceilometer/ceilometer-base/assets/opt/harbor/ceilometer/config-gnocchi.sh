#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=gnocchi
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
crudini --set $cfg DEFAULT dispatcher "gnocchi"
sed -i '2 a dispatcher = database' $cfg
crudini --set $cfg dispatcher_gnocchi filter_project "gnocchi"
crudini --set $cfg dispatcher_gnocchi filter_service_activity "False"
crudini --set $cfg dispatcher_gnocchi archive_policy "low"
crudini --set $cfg dispatcher_gnocchi url "https://gnocchi.${OS_DOMAIN}"
crudini --set $cfg alarms gnocchi_url "https://gnocchi.${OS_DOMAIN}"
