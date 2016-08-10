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
. /opt/harbor/config-neutron.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars cfg ml2_cfg ovs_cfg \
                    NEUTRON_FLAT_NETWORK_NAME \
                    NEUTRON_FLAT_NETWORK_INTERFACE



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Bridge Mappings"
################################################################################
# if the ovs bridge to an external network does not exist then this is just a compute node with no external access,
# this config may create a race condition with the neutron services pod - and so a restart of the neutron service during inital deployment may be required unitll some better logic is added
( ovs-vsctl br-exists br-br1 && crudini --set $ovs_cfg ovs bridge_mappings "${NEUTRON_FLAT_NETWORK_NAME}:${NEUTRON_FLAT_NETWORK_INTERFACE}" ) || crudini --set $ovs_cfg ovs bridge_mappings ""


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Cleaning UP Host"
################################################################################
/usr/bin/neutron-ovs-cleanup --debug


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-openvswitch-agent --config-file $cfg --config-file $ml2_cfg --config-file $ovs_cfg
