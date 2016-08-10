#!/bin/bash
set -o errexit
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
. /opt/harbor/config-manila.sh



cfg=/etc/manila/manila.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Volume config"
################################################################################
# IP address on which OpenStack Volume API listens
#crudini --set $cfg DEFAULT host "manila-default.${OS_DOMAIN}"
crudini --set $cfg DEFAULT interface_driver "manila.network.linux.interface.OVSInterfaceDriver"
crudini --set $cfg DEFAULT ovs_integration_bridge "br-int"

# =
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/sh -c "exec /usr/bin/manila-share --debug --config-file /etc/manila/manila.conf" manila
