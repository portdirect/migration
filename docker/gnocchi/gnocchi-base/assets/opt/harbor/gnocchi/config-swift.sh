#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=database
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${GNOCCHI_KEYSTONE_PROJECT:="gnocchi"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg GNOCCHI_KEYSTONE_USER GNOCCHI_KEYSTONE_PASSWORD GNOCCHI_KEYSTONE_PROJECT \
                        KEYSTONE_AUTH_PROTOCOL KEYSTONE_OLD_PUBLIC_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg storage driver "swift"
crudini --set $cfg storage swift_user "${GNOCCHI_KEYSTONE_USER}_swift"
crudini --set $cfg storage swift_key "${GNOCCHI_KEYSTONE_PASSWORD}"
crudini --set $cfg storage swift_tenant_name "${GNOCCHI_KEYSTONE_PROJECT}"
crudini --set $cfg storage swift_auth_version "2"
crudini --set $cfg storage swift_authurl "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_OLD_PUBLIC_SERVICE_HOST}/v2.0/"
