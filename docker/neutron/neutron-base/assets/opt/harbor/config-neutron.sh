#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

OPENSTACK_SUBCOMPONENT=common-config

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


# Database
: ${NEUTRON_DB_NAME:=neutron}
: ${NEUTRON_DB_USER:=neutron}
: ${NEUTRON_DB_PASSWORD:=password}
# Keystone
: ${ADMIN_TENANT_NAME:=admin}
: ${NEUTRON_KEYSTONE_USER:=neutron}
: ${NEUTRON_KEYSTONE_PASSWORD:=password}

# Logging
: ${VERBOSE_LOGGING:=true}
: ${DEBUG_LOGGING:=false}


: ${ADMIN_USER:="admin"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${SERVICE_TENANT_NAME:="services"}

: ${DEFAULT_REGION:="HarborOS"}






: ${NEUTRON_LOG_DIR:="/var/log/neutron"}


: ${NEUTRON_GATEWAY_IP:="10.142.0.2"}




: ${DHCP_DRIVER:="neutron.agent.linux.dhcp.Dnsmasq"}
: ${USE_NAMESPACES:="true"}
: ${DELETE_NAMESPACES:="true"}
: ${DNSMASQ_CONFIG_FILE:="/etc/neutron/dnsmasq/dnsmasq-neutron.conf"}
: ${ROOT_HELPER:="sudo neutron-rootwrap /etc/neutron/rootwrap.conf"}



: ${EXTERNAL_NET_NAME:="The-World"}
: ${EXTERNAL_SUBNET_NAME:="1-subnet"}
: ${GATEWAY_IP:="10.128.0.1"}
: ${DEFAULT_DNS:="10.40.0.128"}
: ${EXTERNAL_POOL_START:="10.128.1.1"}
: ${EXTERNAL_POOL_END:="10.254.255.255"}
: ${EXTERNAL_NET:="10.128.0.0/9"}


: ${TUNNEL_MTU_OVERHEAD:="50"}




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars NEUTRON_KEYSTONE_PASSWORD \
                    KEYSTONE_PUBLIC_SERVICE_HOST RABBITMQ_SERVICE_HOST OS_DOMAIN



export cfg=/etc/neutron/neutron.conf
export ml2_cfg=/etc/neutron/plugins/ml2/ml2_conf.ini
export ovs_cfg=/etc/neutron/plugins/ml2/openvswitch_agent.ini
export l3_cfg=/etc/neutron/l3_agent.ini
export metadata_agent_cfg=/etc/neutron/metadata_agent.ini
export dhcp_agent_cfg=/etc/neutron/dhcp_agent.ini
export lbass_cfg=/etc/neutron/neutron_lbaas.conf
export lbass_agent_cfg=/etc/neutron/lbaas_agent.ini


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/neutron/config-rabbitmq.sh
. /opt/harbor/neutron/config-keystone.sh
. /opt/harbor/neutron/config-ceilometer.sh
. /opt/harbor/neutron/config-ml2.sh
. /opt/harbor/neutron/config-lbaas.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $cfg DEFAULT verbose "${DEBUG}"
crudini --set $cfg DEFAULT debug "${DEBUG}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Instance Domain"
################################################################################
crudini --set $cfg DEFAULT dns_domain "in.${OS_DOMAIN}"
crudini --del $dhcp_agent_cfg DEFAULT dhcp_domain


# crudini --set $cfg DEFAULT external_dns_driver "designate"
#
# crudini --set $cfg designate url "${KEYSTONE_AUTH_PROTOCOL}://designate.${OS_DOMAIN}/v2"
# crudini --set $cfg designate admin_auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_OLD_ADMIN_SERVICE_HOST}:35357/v2.0"
# crudini --set $cfg designate admin_username "${NEUTRON_KEYSTONE_USER}"
# crudini --set $cfg designate admin_password "${NEUTRON_KEYSTONE_PASSWORD}"
# crudini --set $cfg designate admin_tenant_name "${SERVICE_TENANT_NAME}"
#
# crudini --set $cfg designate ptr_zone_email ""
# crudini --set $cfg designate allow_reverse_dns_lookup "True"
# crudini --set $cfg designate ipv4_ptr_zone_prefix_size "24"
# crudini --set $cfg designate ipv6_ptr_zone_prefix_size "116"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: MTU"
################################################################################
crudini --set $cfg DEFAULT advertise_mtu "True"
check_required_vars cfg l3_cfg dhcp_agent_cfg NEUTRON_AGENT_INTERFACE TUNNEL_MTU_OVERHEAD NEUTRON_FLAT_NETWORK_NAME
AGENT_INTERFACE_DEVICE_MTU=$(ip link show ${NEUTRON_AGENT_INTERFACE} | head -1 | awk -F 'mtu ' '{print $2}' | awk '{print $1}')

if [ -z "${AGENT_INTERFACE_DEVICE_MTU}" ]; then
    echo "This container cannot poll the mtu - setting to 1450 as a safe dafault"
    AGENT_INTERFACE_DEVICE_MTU=1450
fi

INSTANCE_MTU="$((AGENT_INTERFACE_DEVICE_MTU-TUNNEL_MTU_OVERHEAD))"
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: MTU=${INSTANCE_MTU}"
crudini --set $l3_cfg DEFAULT network_device_mtu "${INSTANCE_MTU}"
crudini --set $dhcp_agent_cfg DEFAULT network_device_mtu "${INSTANCE_MTU}"
crudini --set $ml2_cfg ml2 path_mtu "${INSTANCE_MTU}"
crudini --set $ml2_cfg ml2 segment_mtu "${AGENT_INTERFACE_DEVICE_MTU}"
crudini --set $ml2_cfg DEFAULT global_physnet_mtu "${AGENT_INTERFACE_DEVICE_MTU}"
crudini --set $ml2_cfg ml2 physical_network_mtus "${NEUTRON_FLAT_NETWORK_NAME}:${AGENT_INTERFACE_DEVICE_MTU}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Paste"
################################################################################
crudini --set $cfg DEFAULT api_paste_config "/usr/share/neutron/api-paste.ini"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Locking"
################################################################################
crudini --set $cfg oslo_concurrency lock_path "/var/lock/neutron"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Rootwrap"
################################################################################
crudini --set $cfg agent root_helper "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"
