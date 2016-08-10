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
: ${SERVICE_TENANT_NAME:=services}

: ${DEFAULT_REGION:="HarborOS"}



: ${TYPE_DRIVERS:="flat,vxlan"}
: ${TENANT_NETWORK_TYPES:="flat,vxlan"}
: ${MECHANISM_DRIVERS:="linuxbridge,l2population"}
: ${NEUTRON_FLAT_NETWORK_NAME:="physnet1"}
: ${NEUTRON_FLAT_NETWORK_INTERFACE:="br1"}
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


: ${NEUTRON_AGENT_INTERFACE:="br1"}




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars NEUTRON_KEYSTONE_PASSWORD \
                    KEYSTONE_PUBLIC_SERVICE_HOST RABBITMQ_SERVICE_HOST OS_DOMAIN





export cfg=/etc/neutron/neutron.conf
export ml2_cfg=/etc/neutron/plugins/ml2/ml2_conf.ini


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/neutron/config-rabbitmq.sh
/opt/harbor/neutron/config-keystone.sh
/opt/harbor/neutron/config-ceilometer.sh
/opt/harbor/neutron/config-ml2.sh
/opt/harbor/neutron/config-lbaas.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $cfg DEFAULT verbose "${DEBUG}"
crudini --set $cfg DEFAULT debug "${DEBUG}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Instance Domain"
################################################################################
crudini --set $cfg DEFAULT dns_domain "open.${OS_DOMAIN}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Paste"
################################################################################
crudini --set $cfg DEFAULT api_paste_config "/usr/share/neutron/api-paste.ini"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Locking"
################################################################################
crudini --set $cfg DEFAULT lock_path "/var/lock/neutron"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Rootwrap"
################################################################################
crudini --set $cfg agent root_helper "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"
