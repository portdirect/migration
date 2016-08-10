#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=common-config

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
: ${SERVICE_TENANT_NAME:="services"}
: ${DEFAULT_REGION:="HarborOS"}
: ${HEAT_DOMAIN:="heat"}
: ${HEAT_API_CFN_SERVICE_PORT:="8000"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars HEAT_DB_PASSWORD HEAT_KEYSTONE_PASSWORD \
                    KEYSTONE_PUBLIC_SERVICE_HOST RABBITMQ_SERVICE_HOST \
                    HEAT_API_CFN_SERVICE_PORT ETCDCTL_ENDPOINT

fail_unless_db
dump_vars

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Heat Domain ID"
################################################################################
HEAT_DOMAIN_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/heat-domain-id)"
check_required_vars HEAT_DOMAIN_ID


export cfg=/etc/heat/heat.conf
################################################################################
echo "${OS_DISTRO}: Heat-API: Updating Config"
################################################################################
crudini --set $cfg DEFAULT use_stderr "true"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/heat/config-rabbitmq.sh
/opt/harbor/heat/config-database.sh
/opt/harbor/heat/config-keystone.sh

################################################################################
echo "${OS_DISTRO}: CONFIG: HEAT-CFN "
################################################################################
crudini --set $cfg DEFAULT heat_metadata_server_url "${KEYSTONE_AUTH_PROTOCOL}://${HEAT_API_CFN_SERVICE_HOST}"
crudini --set $cfg DEFAULT heat_waitcondition_server_url "${KEYSTONE_AUTH_PROTOCOL}://${HEAT_API_CFN_SERVICE_HOST}/v1/waitcondition"


################################################################################
echo "${OS_DISTRO}: CONFIG: HEAT-CLOUDWATCH "
################################################################################
crudini --set $cfg DEFAULT heat_watch_server_url "${KEYSTONE_AUTH_PROTOCOL}://${HEAT_API_CLOUDWATCH_SERVICE_HOST}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Clients"
################################################################################
crudini --set $cfg clients_keystone auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}:443"
crudini --set $cfg clients insecure "False"
crudini --set $cfg clients ca_file "/etc/pki/tls/certs/ca-bundle.crt"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Allow Users to Adbandon Stacks"
################################################################################
crudini --set $cfg DEFAULT enable_stack_abandon "True"
