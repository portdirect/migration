#!/bin/bash
OPENSTACK_SUBCOMPONENT=api-domain
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



###############################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars  KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_DB_NAME MARIADB_SERVICE_HOST KEYSTONE_DB_USER KEYSTONE_DB_PASSWORD
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${KEYSTONE_DB_NAME}
fail_unless_os_service_running keystone


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Looping back primary keystone API to localhost"
################################################################################
echo "127.0.0.1       ${KEYSTONE_ADMIN_SERVICE_HOST}" >> /etc/hosts
echo "127.0.0.1       ${KEYSTONE_PUBLIC_SERVICE_HOST}" >> /etc/hosts


export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: CONFIG"
################################################################################
crudini --set $cfg DEFAULT debug "True"
/opt/harbor/config-keystone.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Default Domain ID from ETCD"
################################################################################
DEFAULT_DOMAIN_ID=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/default_domain_id)
check_required_vars DEFAULT_DOMAIN_ID

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring to make the ${DEFAULT_DOMAIN_ID} the default for v2 requests"
################################################################################
crudini --set $cfg identity default_domain_id "${DEFAULT_DOMAIN_ID}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
exec httpd -D FOREGROUND
