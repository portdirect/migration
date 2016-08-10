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


export cfg=/etc/neutron/neutron.conf
export ml2_cfg=/etc/neutron/plugins/ml2/ml2_conf.ini
export ovs_cfg=/etc/neutron/plugins/ml2/openvswitch_agent.ini
export l3_cfg=/etc/neutron/l3_agent.ini

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars VERBOSE_LOGGING DEBUG_LOGGING







################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $cfg DEFAULT log_file "${NEUTRON_L3_AGENT_LOG_FILE}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configure"
################################################################################
crudini --set $l3_cfg DEFAULT verbose "${VERBOSE_LOGGING}"
crudini --set $l3_cfg DEFAULT debug "${DEBUG_LOGGING}"
if [[ "${MECHANISM_DRIVERS}" =~ linuxbridge ]] ; then
  crudini --set $l3_cfg   DEFAULT   interface_driver   "neutron.agent.linux.interface.BridgeInterfaceDriver"
  crudini --set $l3_cfg   DEFAULT   gateway_external_network_id   ""
  crudini --set $l3_cfg   DEFAULT   external_network_bridge   ""
elif [[ "${MECHANISM_DRIVERS}" =~ .*openvswitch* ]] ; then
  crudini --set $l3_cfg   DEFAULT   interface_driver   "neutron.agent.linux.interface.OVSInterfaceDriver"
  crudini --set $l3_cfg   DEFAULT   gateway_external_network_id   ""
  crudini --set $l3_cfg   DEFAULT   external_network_bridge   ""
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configure: Namespaces"
################################################################################
crudini --set $l3_cfg DEFAULT use_namespaces "${USE_NAMESPACES}"
if [ "${USE_NAMESPACES}" == "false" ] ; then
  source /openrc
  # Create router if it does not exist
  /usr/bin/neutron router-list | grep admin-router || /usr/bin/neutron router-create admin-router
  # Set router-id
  crudini --set $l3_cfg   DEFAULT   router_id   "$(/usr/bin/neutron router-list | awk '/ admin-router / {print $2}')"
elif [ "${USE_NAMESPACES}" == "true" ] ; then
  crudini --set $l3_cfg   DEFAULT   router_delete_namespaces   "true"
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
exec /usr/bin/neutron-l3-agent --config-file $cfg --config-file $ml2_cfg --config-file $ovs_cfg --config-file $l3_cfg
