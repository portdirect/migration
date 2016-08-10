#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=LVMVolumeDriver
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
# Cinder Volume
: ${GLUSTER_FS_SHARE:="glusterfs.${OS_DOMAIN}:/os-cinder"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: LVMVolumeDriver"
################################################################################

crudini --set $cfg DEFAULT enabled_backends "LVMVolumeDriver"
crudini --set $cfg LVMVolumeDriver volume_backend_name "LVMVolumeDriver"
crudini --set $cfg LVMVolumeDriver volume_driver "cinder.volume.drivers.lvm.LVMVolumeDriver"
crudini --set $cfg LVMVolumeDriver lvm_type "thin"
crudini --set $cfg LVMVolumeDriver lvm_max_over_subscription_ratio "1.5"
