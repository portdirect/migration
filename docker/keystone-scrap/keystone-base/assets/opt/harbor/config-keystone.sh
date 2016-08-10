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
. /opt/harbor/keystone-vars.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_DB_PASSWORD KEYSTONE_DB_NAME KEYSTONE_DB_USER MARIADB_SERVICE_HOST \
                    KEYSTONE_ADMIN_TOKEN \
                    TOKEN_PROVIDER
dump_vars



# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/keystone/config-database.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Token Configuration"
################################################################################
crudini --set $cfg DEFAULT admin_token "${KEYSTONE_ADMIN_TOKEN}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging Configuration"
################################################################################
crudini --set $cfg DEFAULT verbose ${DEBUG}
crudini --set $cfg DEFAULT debug ${DEBUG}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Token Management Configuration"
################################################################################
crudini --set $cfg token provider keystone.token.providers."${TOKEN_PROVIDER}".Provider
crudini --set $cfg token driver keystone.token.persistence.backends."${TOKEN_DRIVER}".Token
crudini --set $cfg revoke driver keystone.contrib.revoke.backends."${TOKEN_DRIVER}".Revoke


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Applying V3 specific paste ini"
################################################################################
crudini --set $cfg paste_deploy config_file "/etc/keystone/keystone-paste.ini"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting keystone to use domain specific drivers"
################################################################################
crudini --set $cfg identity domain_specific_drivers_enabled true
crudini --set $cfg identity domain_configurations_from_database true
