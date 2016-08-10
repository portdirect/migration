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
check_required_vars KEYSTONE_DB_PASSWORD KEYSTONE_DB_NAME KEYSTONE_DB_USER MARIADB_SERVICE_HOST
dump_vars



# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/keystone/config-database.sh
/opt/harbor/keystone/config-tokens.sh
/opt/harbor/keystone/config-domains.sh
/opt/harbor/keystone/config-api-pipeline.sh
/opt/harbor/keystone/config-federation.sh


###############################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: APACHE"
################################################################################
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/conf.d/wsgi-keystone.conf
sed -i "s/{{ KEYSTONE_ADMIN_SERVICE_HOST }}/${KEYSTONE_ADMIN_SERVICE_HOST}/" /etc/httpd/conf.d/wsgi-keystone.conf
