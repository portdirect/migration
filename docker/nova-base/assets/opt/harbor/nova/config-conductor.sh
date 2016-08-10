#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=conductor
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


crudini --set $cfg DEFAULT instance_usage_audit "True"
crudini --set $cfg DEFAULT instance_usage_audit_period "hour"
crudini --set $cfg DEFAULT notify_on_state_change "vm_and_task_state"
crudini --set $cfg DEFAULT notification_driver "messagingv2"
