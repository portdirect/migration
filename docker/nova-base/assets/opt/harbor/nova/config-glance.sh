#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=glance
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg GLANCE_API_SERVICE_HOST KEYSTONE_AUTH_PROTOCOL


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg glance host "${GLANCE_API_SERVICE_HOST}"
crudini --set $cfg glance protocol "${KEYSTONE_AUTH_PROTOCOL}"
crudini --set $cfg glance port "443"
crudini --set $cfg glance api_servers "${KEYSTONE_AUTH_PROTOCOL}://${GLANCE_API_SERVICE_HOST}:443"
crudini --set $cfg DEFAULT image_service "nova.image.glance.GlanceImageService"
