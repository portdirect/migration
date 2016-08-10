#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=object-config
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg SWIFT_DEVICE
SWIFT_IP=$(ip -f inet -o addr show $SWIFT_DEVICE|cut -d\  -f 7 | cut -d/ -f 1)


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RUNNING"
################################################################################
crudini --set $cfg DEFAULT bind_ip "${SWIFT_IP}"
crudini --set $cfg DEFAULT bind_port "6000"
crudini --set $cfg DEFAULT user "swift"
crudini --set $cfg DEFAULT swift_dir "/etc/swift"
crudini --set $cfg DEFAULT devices "/srv/node"
crudini --set $cfg DEFAULT mount_check "False"


crudini --set $cfg pipeline:main pipeline "healthcheck recon object-server"


crudini --set $cfg filter:recon use "egg:swift#recon"
mkdir -p /srv/pod/cache/swift
chown swift:swift /srv/pod/cache/swift
crudini --set $cfg filter:recon recon_cache_path "/srv/pod/cache/swift"
mkdir -p /srv/pod/lock
chown swift:swift /srv/pod/lock
crudini --set $cfg filter:recon recon_lock_path "/srv/pod/lock"
