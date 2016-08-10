#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=ml2
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${TYPE_DRIVERS:="flat,vxlan"}
: ${TENANT_NETWORK_TYPES:="flat,vxlan"}
: ${MECHANISM_DRIVERS:="linuxbridge,l2population"}
: ${NEUTRON_FLAT_NETWORK_NAME:="physnet1"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg ml2_cfg TYPE_DRIVERS TENANT_NETWORK_TYPES MECHANISM_DRIVERS NEUTRON_FLAT_NETWORK_NAME



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ml2 configuration"
################################################################################
crudini --set $cfg DEFAULT core_plugin "neutron.plugins.ml2.plugin.Ml2Plugin"
crudini --set $cfg DEFAULT service_plugins "neutron.services.l3_router.l3_router_plugin.L3RouterPlugin,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPlugin"
crudini --set $cfg DEFAULT allow_overlapping_ips "True"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Drivers"
################################################################################
crudini --set $ml2_cfg ml2 type_drivers "${TYPE_DRIVERS}"
crudini --set $ml2_cfg ml2 tenant_network_types "${TENANT_NETWORK_TYPES}"
crudini --set $ml2_cfg ml2 mechanism_drivers "${MECHANISM_DRIVERS}"

if [[ ${TYPE_DRIVERS} =~ .*flat.* ]]; then
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Drivers: Flat"
  ################################################################################
  crudini --set $ml2_cfg ml2_type_flat flat_networks ${NEUTRON_FLAT_NETWORK_NAME}
fi

if [[ ${TYPE_DRIVERS} =~ .*vxlan.* ]]; then
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Drivers: VXLAN"
  ################################################################################
  crudini --set $ml2_cfg ml2_type_vxlan vxlan_group ""
  crudini --set $ml2_cfg ml2_type_vxlan vni_ranges "1:1000"
  crudini --set $ml2_cfg vxlan enable_vxlan "True"
  crudini --set $ml2_cfg vxlan vxlan_group ""
  crudini --set $ml2_cfg vxlan l2_population "True"
  crudini --set $ml2_cfg agent tunnel_types "vxlan"
  crudini --set $ml2_cfg agent vxlan_udp_port "4789"
  crudini --set $cfg DEFAULT network_device_mtu "1450"
fi

crudini --set $ml2_cfg l2pop agent_boot_time "180"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Security Group"
################################################################################
crudini --set $ml2_cfg securitygroup enable_security_group "True"
crudini --set $ml2_cfg securitygroup enable_ipset "True"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Firewall"
################################################################################
if [[ ${MECHANISM_DRIVERS} =~ linuxbridge ]]; then
  firewall_driver="neutron.agent.linux.iptables_firewall.IptablesFirewallDriver"
elif [[ ${MECHANISM_DRIVERS} == "openvswitch" ]]; then
  firewall_driver="neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
fi
crudini --set $ml2_cfg securitygroup firewall_driver "$firewall_driver"
