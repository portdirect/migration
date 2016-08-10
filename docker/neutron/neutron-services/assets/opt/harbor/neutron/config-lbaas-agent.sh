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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars NEUTRON_AGENT_INTERFACE NEUTRON_FLAT_NETWORK_NAME \
                    NEUTRON_FLAT_NETWORK_INTERFACE MECHANISM_DRIVERS



###############################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring dir structure exists"
################################################################################
mkdir -p /var/lib/neutron/lbaas



# s
# crudini --set $cfg DEFAULT auth_strategy "keystone"
# crudini --set $cfg keystone_authtoken auth_plugin "password"
# crudini --set $cfg keystone_authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
# crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"
# crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
# crudini --set $cfg keystone_authtoken user_domain_name "Default"
# crudini --set $cfg keystone_authtoken project_domain_name "Default"
# crudini --set $cfg keystone_authtoken username "${NEUTRON_KEYSTONE_USER}"
# crudini --set $cfg keystone_authtoken password "${NEUTRON_KEYSTONE_PASSWORD}"
# crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"
#
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: loadbalancer"
################################################################################


crudini --set $lbass_agent_cfg DEFAULT debug "${DEBUG}"

if [[ ${MECHANISM_DRIVERS} =~ "linuxbridge" ]]; then
  interface_driver="neutron.agent.linux.interface.BridgeInterfaceDriver"
elif [[ ${MECHANISM_DRIVERS} =~ "openvswitch" ]]; then
  interface_driver="neutron.agent.linux.interface.OVSInterfaceDriver"
fi
crudini --set $lbass_agent_cfg DEFAULT interface_driver ${interface_driver}

crudini --set $lbass_agent_cfg DEFAULT device_driver 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver'
useradd -G haproxy nouser
crudini --set $lbass_agent_cfg haproxy user_group haproxy

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing any existing loadbalancer namespaces"
################################################################################
ip netns list | grep qlbaas | while read -r line ; do
  ip netns delete $line
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-lbaas-agent --config-file $cfg --config-file $ml2_cfg --config-file $ovs_cfg --config-file $lbass_cfg --config-file $lbass_agent_cfg
