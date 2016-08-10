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
# Cinder Backup
: ${CINDER_BACKUP_MANAGER:="cinder.backup.manager.BackupManager"}
: ${CINDER_BACKUP_API_CLASS:="cinder.backup.api.API"}
: ${CINDER_BACKUP_NAME_TEMPLATE:="backup-%s"}
: ${CINDER_BACKUP_DRIVER:="cinder.backup.drivers.swift"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars CINDER_BACKUP_DRIVER CINDER_BACKUP_MANAGER \
                    CINDER_BACKUP_API_CLASS CINDER_BACKUP_NAME_TEMPLATE


cfg=/etc/cinder/cinder.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
crudini --set $cfg DEFAULT backup_driver "${CINDER_BACKUP_DRIVER}"
crudini --set $cfg DEFAULT backup_topic "cinder-backup"
crudini --set $cfg DEFAULT backup_manager "${CINDER_BACKUP_MANAGER}"
crudini --set $cfg DEFAULT backup_api_class "${CINDER_BACKUP_API_CLASS}"
crudini --set $cfg DEFAULT backup_name_template "${CINDER_BACKUP_NAME_TEMPLATE}"


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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Starting cinder-backup"
################################################################################
exec /usr/bin/cinder-backup --config-file $cfg
