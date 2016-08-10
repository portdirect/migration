#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=services-lbaas
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
check_required_vars NEUTRON_AGENT_INTERFACE NEUTRON_FLAT_NETWORK_NAME \
                    NEUTRON_FLAT_NETWORK_INTERFACE




cfg=/etc/neutron/neutron_lbaas.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring dir structure exists"
################################################################################
mkdir -p /var/lib/neutron/lbaas

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Keystone"
################################################################################

crudini --set $cfg service_auth auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
crudini --set $cfg service_auth admin_tenant_name = "${SERVICE_TENANT_NAME}"
crudini --set $cfg service_auth admin_user "${NEUTRON_KEYSTONE_USER}"
crudini --set $cfg service_auth admin_password = "${NEUTRON_KEYSTONE_PASSWORD}"
crudini --set $cfg service_auth admin_user_domain = "Default"
crudini --set $cfg service_auth admin_project_domain = "Default"


crudini --set $cfg DEFAULT auth_strategy "keystone"
crudini --set $cfg keystone_authtoken auth_plugin "password"
crudini --set $cfg keystone_authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"
crudini --set $cfg keystone_authtoken username "${NEUTRON_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken password "${NEUTRON_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: loadbalancer"
################################################################################
crudini --set $cfg service_providers service_provider 'LOADBALANCER:Haproxy:neutron_lbaas.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default'

agent_cfg=/etc/neutron/lbaas_agent.ini

##[DEFAULT]
# Show debugging output in log (sets DEBUG log level output).
crudini --set $agent_cfg DEFAULT debug "${DEBUG}"

# The LBaaS agent will resync its state with Neutron to recover from any
# transient notification or rpc errors. The interval is number of
# seconds between attempts.
# periodic_interval = 10

# LBaas requires an interface driver be set. Choose the one that best
# matches your plugin.
# interface_driver =

# Example of interface_driver option for OVS based plugins (OVS, Ryu, NEC, NVP,
# BigSwitch/Floodlight)
# interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver

# Use veth for an OVS interface or not.
# Support kernels with limited namespace support
# (e.g. RHEL 6.5) so long as ovs_use_veth is set to True.
# ovs_use_veth = False

# Example of interface_driver option for LinuxBridge
crudini --set $agent_cfg DEFAULT interface_driver 'neutron.agent.linux.interface.BridgeInterfaceDriver'

# The agent requires drivers to manage the loadbalancer.  HAProxy is the opensource version.
# Multiple device drivers reflecting different service providers could be specified:
# device_driver = path.to.provider1.driver.Driver
# device_driver = path.to.provider2.driver.Driver
# Default is:
crudini --set $agent_cfg DEFAULT device_driver 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver'

##[haproxy]
# Location to store config and state files
# loadbalancer_state_path = $state_path/lbaas

# The user group
useradd -G haproxy nouser
crudini --set $agent_cfg haproxy user_group haproxy

# When delete and re-add the same vip, send this many gratuitous ARPs to flush
# the ARP cache in the Router. Set it below or equal to 0 to disable this feature.
# send_gratuitous_arp = 3

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing any existing loadbalancer namespaces"
################################################################################
ip netns list | grep qlbaas | while read -r line ; do
  ip netns delete $line
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-lbaas-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/neutron_lbaas.conf --config-dir /etc/neutron --config-file /etc/neutron/lbaas_agent.ini
