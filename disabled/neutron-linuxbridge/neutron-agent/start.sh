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
check_required_vars NEUTRON_AGENT_INTERFACE NEUTRON_FLAT_NETWORK_NAME \
                    NEUTRON_FLAT_NETWORK_INTERFACE TYPE_DRIVERS


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sudo Config"
################################################################################
# Neutron uses rootwrap which requires a tty for sudo.
# Since the container is running in daemon mode, a tty
# is not present and requiretty must be commented out.
if [ ! -f /var/run/sudo-modified ]; then
  chmod 0640 /etc/sudoers
  sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers
  chmod 0440 /etc/sudoers
fi
touch /var/run/sudo-modified


cfg=/etc/neutron/plugins/ml2/ml2_conf.ini
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: ML2"
################################################################################
LOCAL_IP=$(ip -f inet -o addr show $NEUTRON_AGENT_INTERFACE|cut -d\  -f 7 | cut -d/ -f 1)
# Configure ml2_conf.ini
if [[ ${TYPE_DRIVERS} =~ vxlan ]]; then
  crudini --set $cfg   vxlan   local_ip   "${LOCAL_IP}"
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Bridge Mappings"
################################################################################
crudini --set $cfg linux_bridge bridge_mappings "${NEUTRON_FLAT_NETWORK_NAME}:${NEUTRON_FLAT_NETWORK_INTERFACE}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-linuxbridge-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini --config-dir /etc/neutron
