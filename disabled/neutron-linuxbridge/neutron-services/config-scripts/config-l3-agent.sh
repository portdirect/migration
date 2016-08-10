#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=services-l3
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
. /opt/harbor/config-neutron.sh
. /opt/harbor/config-sudoers.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars VERBOSE_LOGGING DEBUG_LOGGING


cfg=/etc/neutron/l3_agent.ini
neutron_conf=/etc/neutron/neutron.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $neutron_conf DEFAULT log_file "${NEUTRON_L3_AGENT_LOG_FILE}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configure"
################################################################################
crudini --set $cfg DEFAULT verbose "${VERBOSE_LOGGING}"
crudini --set $cfg DEFAULT debug "${DEBUG_LOGGING}"
if [[ "${MECHANISM_DRIVERS}" =~ linuxbridge ]] ; then
  crudini --set $cfg   DEFAULT   interface_driver   "neutron.agent.linux.interface.BridgeInterfaceDriver"
  crudini --set $cfg   DEFAULT   gateway_external_network_id   ""
  crudini --set $cfg   DEFAULT   external_network_bridge   ""
elif [[ "${MECHANISM_DRIVERS}" =~ .*openvswitch* ]] ; then
  crudini --set $cfg   DEFAULT   interface_driver   "neutron.agent.linux.interface.OVSInterfaceDriver"
  crudini --set $cfg   DEFAULT   gateway_external_network_id   "${NEUTRON_FLAT_NETWORK_BRIDGE}"
  crudini --set $cfg   DEFAULT   external_network_bridge   "${NEUTRON_FLAT_NETWORK_BRIDGE}"
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configure: Namespaces"
################################################################################
crudini --set $cfg DEFAULT use_namespaces "${USE_NAMESPACES}"
if [ "${USE_NAMESPACES}" == "false" ] ; then
  source /openrc
  # Create router if it does not exist
  /usr/bin/neutron router-list | grep admin-router || /usr/bin/neutron router-create admin-router
  # Set router-id
  crudini --set $cfg   DEFAULT   router_id   "$(/usr/bin/neutron router-list | awk '/ admin-router / {print $2}')"
elif [ "${USE_NAMESPACES}" == "true" ] ; then
  crudini --set $cfg   DEFAULT   router_delete_namespaces   "true"
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing any existing router namespaces"
################################################################################
ip netns list | grep qrouter | while read -r line ; do
  ip netns delete $line
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-l3-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/l3_agent.ini --config-file /etc/neutron/fwaas_driver.ini --config-dir /etc/neutron
