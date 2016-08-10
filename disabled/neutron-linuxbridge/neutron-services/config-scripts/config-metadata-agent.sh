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
: ${ENDPOINT_TYPE:="adminURL"}
: ${NOVA_METADATA_API_SERVICE_HOST:="$(dig +short metadata.gantry.svc.${OS_DOMAIN})"}
: ${NOVA_METADATA_API_SERVICE_PORT:="443"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars VERBOSE_LOGGING DEBUG_LOGGING KEYSTONE_AUTH_PROTOCOL \
                    KEYSTONE_PUBLIC_SERVICE_HOST ADMIN_TENANT_NAME \
                    NEUTRON_KEYSTONE_USER NEUTRON_KEYSTONE_PASSWORD \
                    NEUTRON_SHARED_SECRET NOVA_METADATA_API_SERVICE_HOST \
                    NOVA_METADATA_API_SERVICE_PORT OS_DOMAIN


cfg=/etc/neutron/metadata_agent.ini
neutron_conf=/etc/neutron/neutron.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $cfg DEFAULT verbose "${DEBUG}"
crudini --set $cfg DEFAULT debug "${DEBUG}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Keystone"
################################################################################
crudini --set $cfg DEFAULT auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/"
crudini --set $cfg DEFAULT auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg DEFAULT auth_region "${DEFAULT_REGION}"
crudini --set $cfg DEFAULT auth_plugin password
crudini --set $cfg DEFAULT project_domain_id "default"
crudini --set $cfg DEFAULT user_domain_id "default"
crudini --set $cfg DEFAULT project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg DEFAULT username "${NEUTRON_KEYSTONE_USER}"
crudini --set $cfg DEFAULT password "${NEUTRON_KEYSTONE_PASSWORD}"
crudini --set $cfg DEFAULT auth_ca_cert "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
crudini --set $cfg DEFAULT auth_insecure "false"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Endpoint"
################################################################################
crudini --set $cfg DEFAULT endpoint_type "${ENDPOINT_TYPE}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Nova: Metadata"
################################################################################
crudini --set $cfg DEFAULT nova_metadata_ip "metadata.${OS_DOMAIN}"
crudini --set $cfg DEFAULT nova_metadata_port "443"
crudini --set $cfg DEFAULT nova_metadata_protocol "${KEYSTONE_AUTH_PROTOCOL}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Shared Secret"
################################################################################
crudini --set $cfg DEFAULT metadata_proxy_shared_secret "${NEUTRON_SHARED_SECRET}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-metadata-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/metadata_agent.ini --config-dir /etc/neutron --debug
