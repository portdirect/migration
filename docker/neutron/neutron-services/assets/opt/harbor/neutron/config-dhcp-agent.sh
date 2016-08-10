#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=services-dhcp
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Environment Variables"
################################################################################
check_required_vars VERBOSE_LOGGING DEBUG_LOGGING MECHANISM_DRIVERS \
                    DHCP_DRIVER USE_NAMESPACES DELETE_NAMESPACES \
                    NEUTRON_LOG_DIR DNSMASQ_CONFIG_FILE


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Fixing routing for dhclient bugs in some guest images"
################################################################################
# Workaround bug in dhclient in cirros images which does not correctly
# handle setting checksums of packets when using hardware with checksum
# offloading.  See:
# https://www.rdoproject.org/forum/discussion/567/packstack-allinone-grizzly-cirros-image-cannot-get-a-dhcp-address-when-a-centos-image-can/p1
/usr/sbin/iptables -A POSTROUTING -t mangle -p udp --dport bootpc -j CHECKSUM --checksum-fill



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $cfg DEFAULT log_file "${NEUTRON_DHCP_AGENT_LOG_FILE}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
if [[ ${MECHANISM_DRIVERS} =~ "linuxbridge" ]]; then
  interface_driver="neutron.agent.linux.interface.BridgeInterfaceDriver"
elif [[ ${MECHANISM_DRIVERS} =~ "openvswitch" ]]; then
  interface_driver="neutron.agent.linux.interface.OVSInterfaceDriver"
fi
crudini --set $dhcp_agent_cfg DEFAULT verbose "${VERBOSE_LOGGING}"
crudini --set $dhcp_agent_cfg DEFAULT debug "${DEBUG_LOGGING}"
crudini --set $dhcp_agent_cfg DEFAULT interface_driver "$interface_driver"
crudini --set $dhcp_agent_cfg DEFAULT dhcp_driver "${DHCP_DRIVER}"
crudini --set $dhcp_agent_cfg DEFAULT use_namespaces "${USE_NAMESPACES}"
crudini --set $dhcp_agent_cfg DEFAULT delete_namespaces "${DELETE_NAMESPACES}"
crudini --set $dhcp_agent_cfg DEFAULT dnsmasq_config_file "${DNSMASQ_CONFIG_FILE}"
crudini --set $dhcp_agent_cfg DEFAULT root_helper "${ROOT_HELPER}"
crudini --set $dhcp_agent_cfg DEFAULT enable_isolated_metadata "True"
crudini --set $dhcp_agent_cfg DEFAULT force_metadata "True"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring dnsmasq config dir exists"
################################################################################
mkdir -p $(dirname $DNSMASQ_CONFIG_FILE)


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating dnsmasq config"
################################################################################
check_required_vars DNSMASQ_CONFIG_FILE NEUTRON_AGENT_INTERFACE TUNNEL_MTU_OVERHEAD
AGENT_INTERFACE_DEVICE_MTU=$(ip link show ${NEUTRON_AGENT_INTERFACE} | head -1 | awk -F 'mtu ' '{print $2}' | awk '{print $1}')
INSTANCE_MTU="$((AGENT_INTERFACE_DEVICE_MTU-TUNNEL_MTU_OVERHEAD))"

#dhcp-option-force=26,1450
cat > ${DNSMASQ_CONFIG_FILE} <<EOF
log-facility=${NEUTRON_LOG_DIR}/neutron-dnsmasq.log
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing any existing dhcp namespaces"
################################################################################
ip netns list | grep qdhcp | while read -r line ; do
  ip netns delete $line
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-dhcp-agent --config-file $cfg --config-file $ml2_cfg --config-file $ovs_cfg --config-file $dhcp_agent_cfg --debug
