#!/bin/sh
OPENSTACK_SUBCOMPONENT=swift-common
set -e
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars SWIFT_HASH_PATH_SUFFIX SWIFT_HASH_PATH_PREFIX

core_cfg=/etc/swift/swift.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RUNNING"
################################################################################

crudini --set $core_cfg swift-hash swift_hash_path_suffix "${SWIFT_HASH_PATH_SUFFIX}"
crudini --set $core_cfg swift-hash swift_hash_path_prefix "${SWIFT_HASH_PATH_PREFIX}"


crudini --set $core_cfg storage-policy:0 name "Policy-0"
crudini --set $core_cfg storage-policy:0 default "yes"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configureing Recon Cache Dir"
################################################################################
mkdir -p /var/cache/swift
chown -R 160:160 /var/cache/swift
chown -R 160:160 /var/lock
