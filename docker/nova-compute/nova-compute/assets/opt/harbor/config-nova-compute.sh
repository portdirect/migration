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
. /opt/harbor/config-nova.sh
: ${NOVA_VNCSERVER_PROXYCLIENT_INTERFACE:="br0"}



cfg=/etc/nova/nova.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Libvirt"
################################################################################
crudini --set $cfg libvirt qemu_allowed_storage_drivers ""
# set qmeu emulation if no hardware acceleration found
if [[ `egrep -c '(vmx|svm)' /proc/cpuinfo` == 0 ]]; then
    crudini --set $cfg libvirt virt_type "qemu"
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ceilometer"
################################################################################
crudini --set $cfg DEFAULT compute_monitors "nova.compute.monitors.cpu"
crudini --set $cfg DEFAULT linuxnet_interface_driver "nova.network.linux_net.LinuxOVSInterfaceDriver"


NOVA_VNCSERVER_PROXYCLIENT_ADDRESS=$(ip -f inet -o addr show ${NOVA_VNCSERVER_PROXYCLIENT_INTERFACE}|cut -d\  -f 7 | cut -d/ -f 1)
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: VNC: ${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
################################################################################
crudini --set $cfg DEFAULT vnc_enabled "True"
crudini --set $cfg DEFAULT vncserver_listen "${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
crudini --set $cfg DEFAULT vncserver_proxyclient_address "${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
crudini --set $cfg DEFAULT novncproxy_base_url "https://novnc.${OS_DOMAIN}/vnc_auto.html"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Spice: ${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
################################################################################
crudini --set $cfg DEFAULT web "/usr/share/spice-html5"
crudini --set $cfg spice html5proxy_base_url "https://spice.${OS_DOMAIN}/spice_auto.html"
crudini --set $cfg spice server_listen "${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
crudini --set $cfg spice server_proxyclient_address "${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
crudini --set $cfg spice enabled "True"
crudini --set $cfg spice agent_enabled "true"
crudini --set $cfg spice keymap "en-us"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Serial: ${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
################################################################################
crudini --set $cfg serial_console base_url "wss://serial.${OS_DOMAIN}/"
crudini --set $cfg serial_console enabled "True"
crudini --set $cfg serial_console listen "${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
crudini --set $cfg serial_console proxyclient_address "${NOVA_VNCSERVER_PROXYCLIENT_ADDRESS}"
crudini --set $cfg serial_console serialproxy_host "0.0.0.0"
crudini --set $cfg serial_console serialproxy_port "6083"
