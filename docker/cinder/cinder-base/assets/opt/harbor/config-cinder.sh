#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=common-config
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
/opt/harbor/cinder/config-glusterfs.sh
#/opt/harbor/cinder/config-lvm.sh
/opt/harbor/cinder/config-keystone.sh
/opt/harbor/cinder/config-glance.sh
/opt/harbor/cinder/config-ceilometer.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: API versions"
################################################################################
crudini --set $cfg DEFAULT enable_v1_api "false"
crudini --set $cfg DEFAULT enable_v2_api "true"



################################################################################
echo "${OS_DISTRO}: Cinder: Config: ENCRYPTION"
################################################################################
crudini --set /etc/cinder/cinder.conf keymgr encryption_auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/v3"
crudini --set /etc/cinder/cinder.conf keymgr encryption_api_url "${KEYSTONE_AUTH_PROTOCOL}://${BARBICAN_API_SERVICE_HOST}/v1"
crudini --set /etc/cinder/cinder.conf keymgr api_class "cinder.keymgr.barbican.BarbicanKeyManager"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Concurrency Locks"
################################################################################
crudini --set $cfg oslo_concurrency disable_process_locking True
mkdir -p /var/lib/cinder/locks
crudini --set $cfg oslo_concurrency lock_path /var/lib/cinder/locks


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Setting Default Volume Type"
################################################################################
crudini --set $cfg DEFAULT default_volume_type "LVMVolume"
