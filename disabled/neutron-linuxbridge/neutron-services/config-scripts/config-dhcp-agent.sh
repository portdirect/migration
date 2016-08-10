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
. /opt/harbor/config-sudoers.sh


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


cfg=/etc/neutron/dhcp_agent.ini
neutron_conf=/etc/neutron/neutron.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $neutron_conf DEFAULT log_file "${NEUTRON_DHCP_AGENT_LOG_FILE}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
if [[ ${MECHANISM_DRIVERS} =~ "linuxbridge" ]]; then
  interface_driver="neutron.agent.linux.interface.BridgeInterfaceDriver"
elif [[ ${MECHANISM_DRIVERS} == "openvswitch" ]]; then
  interface_driver="neutron.agent.linux.interface.OVSInterfaceDriver"
fi
crudini --set $cfg DEFAULT verbose "${VERBOSE_LOGGING}"
crudini --set $cfg DEFAULT debug "${DEBUG_LOGGING}"
crudini --set $cfg DEFAULT interface_driver "$interface_driver"
crudini --set $cfg DEFAULT dhcp_driver "${DHCP_DRIVER}"
crudini --set $cfg DEFAULT use_namespaces "${USE_NAMESPACES}"
crudini --set $cfg DEFAULT delete_namespaces "${DELETE_NAMESPACES}"
crudini --set $cfg DEFAULT dnsmasq_config_file "${DNSMASQ_CONFIG_FILE}"
crudini --set $cfg DEFAULT root_helper "${ROOT_HELPER}"




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring dnsmasq config dir exists"
################################################################################
mkdir -p $(dirname $DNSMASQ_CONFIG_FILE)


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating dnsmasq config"
################################################################################
cat > ${DNSMASQ_CONFIG_FILE} <<EOF
dhcp-option-force=26,1450
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
exec /usr/bin/neutron-dhcp-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/dhcp_agent.ini --config-dir /etc/neutron
