#!/bin/sh

set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi



################################################################################
echo "${OS_DISTRO}: Setting Up tgtd"
################################################################################
source /etc/sysconfig/tgtd
(
# see bz 848942. workaround for a race for now.
/bin/sleep 5
# Put tgtd into "offline" state until all the targets are configured.
# We don't want initiators to (re)connect and fail the connection
# if it's not ready.
/usr/sbin/tgtadm --op update --mode sys --name State -v offline
# Configure the targets.
/usr/sbin/tgt-admin -e -c $TGTD_CONFIG
# Put tgtd into "ready" state.
/usr/sbin/tgtadm --op update --mode sys --name State -v ready
# Update configuration for targets. Only targets which
# are not in use will be updated.
/usr/sbin/tgt-admin --update ALL -c $TGTD_CONFIG
)&
/usr/sbin/tgtd $TGTD_OPTS



DEVICE=sdb
################################################################################
echo "${OS_DISTRO}: Setting Up device ${DEVICE} to be a cinder volume"
################################################################################
HARBOR_GLUSTER_VG=cinder-volumes
pvdisplay /dev/${DEVICE}1 || (
  parted  --script /dev/${DEVICE} mklabel GPT
  parted  --script /dev/${DEVICE} mkpart primary 1MiB 100%
  parted  --script /dev/${DEVICE} set 1 lvm on
  pvcreate /dev/${DEVICE}1
  pvdisplay /dev/${DEVICE}1
)
if vgscan | grep -q "${HARBOR_GLUSTER_VG}"; then
  vgdisplay ${HARBOR_GLUSTER_VG}
else
  vgcreate ${HARBOR_GLUSTER_VG} /dev/${DEVICE}1
  vgdisplay ${HARBOR_GLUSTER_VG}
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Checking Env"
################################################################################
check_required_vars KEYSTONE_ADMIN_SERVICE_HOST DEBUG

dump_vars

export cfg=/etc/cinder/cinder.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Logging"
################################################################################
crudini --set $cfg DEFAULT verbose "${DEBUG}"
crudini --set $cfg DEFAULT debug "${DEBUG}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/cinder/config-rabbitmq.sh
/opt/harbor/cinder/config-database.sh
/opt/harbor/cinder/config-lvm.sh
/opt/harbor/cinder/config-keystone.sh
/opt/harbor/cinder/config-glance.sh
/opt/harbor/cinder/config-ceilometer.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: API versions"
################################################################################
crudini --set $cfg DEFAULT enable_v1_api "false"
crudini --set $cfg DEFAULT enable_v2_api "true"


################################################################################
echo "${OS_DISTRO}: Cinder: Config: encryption_auth_url"
################################################################################
crudini --set /etc/cinder/cinder.conf keymgr encryption_auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:5000/v3"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Concurrency Locks"
################################################################################
crudini --set $cfg oslo_concurrency disable_process_locking True
mkdir -p /var/lib/cinder/locks
crudini --set $cfg oslo_concurrency lock_path /var/lib/cinder/locks

# Cinder Volume API
: ${CINDER_VOLUME_API_LISTEN:="0.0.0.0"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Environment"
################################################################################
check_required_vars CINDER_VOLUME_API_LISTEN


cfg=/etc/cinder/cinder.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Volume config"
################################################################################
# IP address on which OpenStack Volume API listens
crudini --set $cfg DEFAULT osapi_volume_listen "${CINDER_VOLUME_API_LISTEN}"
#crudini --set $cfg DEFAULT host "cinder-glusterfs.${OS_DOMAIN}"
crudini --set $cfg LVMVolumeDriver iscsi_protocol "iscsi"
crudini --set $cfg LVMVolumeDriver iscsi_helper "tgtadm"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Fixing /dev/pts/ptmx permissions"
################################################################################
# https://bugs.launchpad.net/kolla/+bug/1461635
# Cinder requires mounting /dev in the cinder-volume, nova-compute,
# and libvirt containers.  If /dev/pts/ptmx does not have proper permissions
# on the host, then libvirt will fail to boot an instance.
# This is a bug in Docker where it is not correctly mounting /dev/pts
# Tech Debt tracker: https://bugs.launchpad.net/kolla/+bug/1468962
# **Temporary fix**
chmod 666 /dev/pts/ptmx


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching: cinder-volume"
################################################################################
exec /usr/bin/cinder-volume --config-file /etc/cinder/cinder.conf



# NOTE: Shutdown of the iscsi target may cause data corruption
# for initiators that are connected.
ExecStop=/usr/sbin/tgtadm --op update --mode sys --name State -v offline
# Remove all targets. It only removes targets which are not in use.
ExecStop=/usr/sbin/tgt-admin --update ALL -c /dev/null
# tgtd will exit if all targets were removed
ExecStop=/usr/sbin/tgtadm --op delete --mode system
