#!/bin/bash
set -e
OPENSTACK_CONFIG_COMPONENT=ceilometer
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Config"
################################################################################
crudini --set $cfg DEFAULT control_exchange "neutron"
crudini --set $cfg oslo_messaging_notifications driver "messagingv2"
crudini --set $cfg oslo_messaging_notifications topics "notifications,notifications_dns"
