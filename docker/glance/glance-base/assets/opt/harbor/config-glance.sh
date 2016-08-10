#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

OPENSTACK_SUBCOMPONENT=base-config
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

: ${ADMIN_TENANT_NAME:=admin}
: ${GLANCE_DB_NAME:=glance}
: ${GLANCE_DB_USER:=glance}
: ${GLANCE_KEYSTONE_USER:=glance}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_AUTH_PROTOCOL KEYSTONE_PUBLIC_SERVICE_HOST \
                    GLANCE_KEYSTONE_USER GLANCE_KEYSTONE_PASSWORD \
                    DEFAULT_REGION SERVICE_TENANT_NAME \
                    RABBITMQ_SERVICE_HOST RABBITMQ_USER RABBITMQ_PASS \
                    KEYSTONE_ADMIN_SERVICE_HOST  \
                    GLANCE_DB_USER GLANCE_DB_PASSWORD MARIADB_SERVICE_HOST GLANCE_DB_NAME \
                    KEYSTONE_OLD_PUBLIC_SERVICE_HOST \
                    GLANCE_REGISTRY_SERVICE_HOST
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
for CFG_FILE in /etc/glance/glance-api.conf /etc/glance/glance-registry.conf; do
    export cfg=${CFG_FILE}

    crudini --set $cfg DEFAULT debug "${DEBUG}"
    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
    ################################################################################
    /opt/harbor/glance/config-rabbitmq.sh
    /opt/harbor/glance/config-database.sh
    /opt/harbor/glance/config-keystone.sh
done


export cfg=/etc/glance/glance-api.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: API: Config"
################################################################################
/opt/harbor/glance/config-api.sh
