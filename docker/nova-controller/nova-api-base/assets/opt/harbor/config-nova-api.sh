#!/bin/bash
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
. /opt/harbor/config-nova.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars NOVA_DB_NAME


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${NOVA_DB_NAME}
fail_unless_os_service_running keystone



# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching (no TLS)"
# ################################################################################
# exec /usr/bin/nova-api --config-file /etc/nova/nova.conf


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
cfg=/etc/nova/nova.conf
crudini --set $cfg DEFAULT lock_path "/var/lib/nova/tmp"
crudini --set $cfg DEFAULT state_path "/var/lib/nova"
crudini --set $cfg DEFAULT log_dir "/var/log/nova"
crudini --set $cfg DEFAULT keys_path "\$state_path/keys"
