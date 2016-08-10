#!/bin/bash
set -e
OPENSTACK_CONFIG_COMPONENT=ml2
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

: ${TYPE_DRIVERS:="flat,vxlan"}
: ${TENANT_NETWORK_TYPES:="flat,vxlan"}


: ${NEUTRON_AGENT_INTERFACE:="br1"}


: ${MECHANISM_DRIVERS:="openvswitch,l2population"}

: ${NEUTRON_FLAT_NETWORK_NAME:="physnet1"}
: ${NEUTRON_FLAT_NETWORK_INTERFACE:="br-br1"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg ml2_cfg TYPE_DRIVERS TENANT_NETWORK_TYPES MECHANISM_DRIVERS NEUTRON_FLAT_NETWORK_NAME



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: ml2 configuration"
################################################################################
crudini --set $cfg DEFAULT core_plugin "neutron.plugins.ml2.plugin.Ml2Plugin"
crudini --set $cfg DEFAULT service_plugins "neutron.services.l3_router.l3_router_plugin.L3RouterPlugin,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPlugin"
crudini --set $cfg DEFAULT allow_overlapping_ips "True"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Drivers"
################################################################################
crudini --set $ml2_cfg ml2 extension_drivers "port_security,dns"

crudini --set $ml2_cfg ml2 type_drivers "${TYPE_DRIVERS}"
crudini --set $ml2_cfg ml2 tenant_network_types "${TENANT_NETWORK_TYPES}"


crudini --set $ml2_cfg ml2 mechanism_drivers "${MECHANISM_DRIVERS}"
crudini --set $ovs_cfg agent l2_population "True"




if [[ ${TYPE_DRIVERS} =~ .*flat.* ]]; then
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Drivers: Flat"
  ################################################################################
  crudini --set $ml2_cfg ml2_type_flat flat_networks ${NEUTRON_FLAT_NETWORK_NAME}
fi

if [[ ${TYPE_DRIVERS} =~ .*vxlan.* ]]; then
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Drivers: VXLAN"
  ################################################################################
  crudini --set $ml2_cfg ml2_type_vxlan vxlan_group ""
  crudini --set $ml2_cfg ml2_type_vxlan vni_ranges "1:1000"
  crudini --set $ovs_cfg agent tunnel_types "vxlan"
  crudini --set $ovs_cfg agent vxlan_udp_port "4789"
  #crudini --set $cfg DEFAULT network_device_mtu "1450"
fi





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Security Group"
################################################################################
crudini --set $ml2_cfg securitygroup enable_security_group "True"
crudini --set $ml2_cfg securitygroup enable_ipset "True"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Firewall"
################################################################################
crudini --set $ovs_cfg securitygroup firewall_driver "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Security Group"
################################################################################
LOCAL_IP=$(ip -f inet -o addr show ${NEUTRON_AGENT_INTERFACE}|cut -d\  -f 7 | cut -d/ -f 1)
crudini --set $ovs_cfg ovs bridge_mappings "${NEUTRON_FLAT_NETWORK_NAME}:${NEUTRON_FLAT_NETWORK_INTERFACE}"
crudini --set $ovs_cfg ovs local_ip ${LOCAL_IP}
