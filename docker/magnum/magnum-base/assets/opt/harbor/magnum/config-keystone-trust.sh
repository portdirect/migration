#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=trust
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${KEYSTONE_API_VERSION:="3"}
: ${DEFAULT_DOMAIN:="default"}
: ${TRUST_DOMAIN:="magnum"}
: ${MAGNUM_KEYSTONE_TRUST_PASSWORD:="${MAGNUM_KEYSTONE_PASSWORD}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_API_VERSION \
                    SERVICE_TENANT_NAME MAGNUM_KEYSTONE_USER \
                    MAGNUM_KEYSTONE_TRUST_PASSWORD KEYSTONE_API_VERSION ETCDCTL_ENDPOINT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Domain ID"
################################################################################
: ${MAGNUM_TRUST_DOMAIN_ID:="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/trust-domain-id)"}
check_required_vars MAGNUM_TRUST_DOMAIN_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking User ID"
################################################################################
: ${MAGNUM_TRUST_USER_ID:="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/trust-user-id)"}
check_required_vars MAGNUM_TRUST_USER_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
crudini --set $cfg trust trustee_domain_id "${MAGNUM_TRUST_DOMAIN_ID}"
crudini --set $cfg trust trustee_domain_admin_id "${MAGNUM_TRUST_USER_ID}"
crudini --set $cfg trust trustee_domain_admin_password "${MAGNUM_KEYSTONE_TRUST_PASSWORD}"
