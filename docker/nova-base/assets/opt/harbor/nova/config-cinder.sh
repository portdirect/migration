#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=cinder
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg DEFAULT volume_api_class "nova.volume.cinder.API"
crudini --set $cfg DEFAULT osapi_volume_listen "0.0.0.0"
