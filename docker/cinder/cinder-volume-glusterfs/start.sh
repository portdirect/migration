#!/bin/sh
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/config-cinder.sh
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
crudini --set $cfg DEFAULT host "cinder-glusterfs.${OS_DOMAIN}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Fixing /dev/pts/ptmx permissions"
################################################################################
# https://bugs.launchpad.net/harbor/+bug/1461635
# Cinder requires mounting /dev in the cinder-volume, nova-compute,
# and libvirt containers.  If /dev/pts/ptmx does not have proper permissions
# on the host, then libvirt will fail to boot an instance.
# This is a bug in Docker where it is not correctly mounting /dev/pts
# Tech Debt tracker: https://bugs.launchpad.net/harbor/+bug/1468962
# **Temporary fix**
chmod 666 /dev/pts/ptmx


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching: cinder-volume"
################################################################################
exec /usr/bin/cinder-volume --config-file /etc/cinder/cinder.conf
