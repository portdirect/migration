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
: ${HEAT_DOMAIN_ID:="Default"}
export HEAT_DOMAIN_ID="${HEAT_DOMAIN_ID}"
mkdir -p /etc/heat-domain-id
echo "${HEAT_DOMAIN_ID}" > /etc/heat-domain-id/heat-domain-id
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${HEAT_ENGINE_PROCESSES:="2"}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_USER KEYSTONE_ADMIN_SERVICE_HOST \
                    HEAT_KEYSTONE_USER HEAT_KEYSTONE_PASSWORD \
                    HEAT_API_SERVICE_HOST \
                    HEAT_DB_NAME HEAT_DB_USER HEAT_DB_PASSWORD \
                    ETCDCTL_ENDPOINT \
                    MARIADB_HOSTNAME OS_DOMAIN HEAT_API_CFN_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db
fail_unless_os_service_running keystone


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Keystone"
################################################################################
/usr/bin/write-openrc-admin.sh
/usr/bin/keystone-endpoint-manager.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Database"
################################################################################
. /opt/harbor/config-heat.sh
/usr/bin/create-db.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up endpoints"
################################################################################
/bin/ipa-endpoint-manager.sh
/bin/ipa-endpoint-manager-cfn.sh
/bin/ipa-endpoint-manager-cloudwatch.sh


#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Management Complete"
################################################################################
