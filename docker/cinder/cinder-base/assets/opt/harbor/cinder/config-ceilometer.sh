#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=Ceilometer
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg


################################################################################
echo "${OS_DISTRO}: Cinder: Config: Ceilometer"
################################################################################
crudini --set $cfg DEFAULT control_exchange "cinder"
crudini --set $cfg DEFAULT notification_driver "messagingv2"
