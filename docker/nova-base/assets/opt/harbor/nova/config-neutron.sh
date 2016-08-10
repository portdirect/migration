#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=neutron
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${MECHANISM_DRIVERS:="openvswitch,l2population"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg NEUTRON_API_SERVICE_HOST NEUTRON_SHARED_SECRET NEUTRON_KEYSTONE_USER NEUTRON_KEYSTONE_PASSWORD KEYSTONE_ADMIN_SERVICE_HOST MECHANISM_DRIVERS

crudini --set $cfg DEFAULT network_api_class "nova.network.neutronv2.api.API"
crudini --set $cfg DEFAULT use_neutron "True"

crudini --set $cfg neutron url "${KEYSTONE_AUTH_PROTOCOL}://neutron.${OS_DOMAIN}"
crudini --set $cfg neutron service_metadata_proxy "True"
crudini --set $cfg neutron metadata_proxy_shared_secret "${NEUTRON_SHARED_SECRET}"
crudini --set $cfg DEFAULT neutron_default_tenant_id "default"
crudini --set $cfg DEFAULT security_group_api "neutron"
crudini --set $cfg DEFAULT network_device_mtu "1450"
if [[ "${MECHANISM_DRIVERS}" =~ linuxbridge ]] ; then
  crudini --set $cfg DEFAULT "linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver"
elif [[ "${MECHANISM_DRIVERS}" =~ openvswitch ]] ; then
  crudini --set $cfg DEFAULT "linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver"
fi
crudini --set $cfg DEFAULT "libvirt_vif_driver nova.virt.libvirt.vif.LibvirtGenericVIFDriver"
crudini --set $cfg DEFAULT "firewall_driver nova.virt.firewall.NoopFirewallDriver"

# Keystone V3 Config for netron
crudini --set $cfg neutron auth_plugin "password"
crudini --set $cfg neutron auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg neutron username "${NEUTRON_KEYSTONE_USER}"
crudini --set $cfg neutron password "${NEUTRON_KEYSTONE_PASSWORD}"
crudini --set $cfg neutron user_domain_name "Default"
crudini --set $cfg neutron project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg neutron project_domain_name "Default"
crudini --set $cfg neutron region_name "${DEFAULT_REGION}"
