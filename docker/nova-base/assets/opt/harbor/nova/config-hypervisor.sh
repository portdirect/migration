#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=Hypervisor
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Hypervisor"
################################################################################
crudini --set $cfg DEFAULT compute_driver "nova.virt.libvirt.LibvirtDriver"
crudini --set $cfg DEFAULT vif_plugging_is_fatal "True"
crudini --set $cfg DEFAULT vif_plugging_timeout "300"
crudini --set $cfg DEFAULT cpu_allocation_ratio "16.0"
crudini --set $cfg DEFAULT ram_allocation_ratio "1.5"
