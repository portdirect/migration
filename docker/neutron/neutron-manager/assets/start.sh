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
check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_ADMIN_SERVICE_HOST \
                    KEYSTONE_AUTH_PROTOCOL \
                    NOVA_KEYSTONE_USER NOVA_KEYSTONE_PASSWORD \
                    NEUTRON_DB_NAME NEUTRON_DB_USER NEUTRON_DB_PASSWORD \
                    NEUTRON_KEYSTONE_USER NEUTRON_KEYSTONE_PASSWORD \
                    ADMIN_TENANT_NAME NEUTRON_API_SERVICE_HOST \
                    NEUTRON_DB_PASSWORD \
                    ETCDCTL_ENDPOINT



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db
fail_unless_os_service_running keystone



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Database"
################################################################################
/usr/bin/create-db.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Database"
################################################################################
/usr/bin/write-openrc-admin.sh
/usr/bin/keystone-endpoint-manager.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up endpoints"
################################################################################
/bin/ipa-endpoint-manager.sh


#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE


#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Trying to bootstrap every 30s"
################################################################################
until /bin/bootstrap.sh
do
  sleep 30s
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Management Complete"
################################################################################
