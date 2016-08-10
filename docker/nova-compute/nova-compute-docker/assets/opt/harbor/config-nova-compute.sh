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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Docker"
################################################################################
crudini --set $cfg DEFAULT compute_driver "novadocker.virt.docker.DockerDriver"
crudini --set $cfg docker host_url "unix:///var/run/docker-openstack.sock"
crudini --set $cfg docker privileged "False"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ceilometer"
################################################################################
crudini --set $cfg DEFAULT compute_monitors "nova.compute.monitors.cpu"
crudini --set $cfg DEFAULT vnc_enabled "False"
crudini --set $cfg spice enabled "False"
crudini --set $cfg serial_console enabled "False"
crudini --set $cfg DEFAULT linuxnet_interface_driver "nova.network.linux_net.LinuxOVSInterfaceDriver"
