#!/bin/bash
OPENSTACK_COMPONENT="sahara"
COMPONENT_SUBCOMPONET="engine"

################################################################################
echo "${OS_DISTRO}: Global Configuration"
################################################################################
. /opt/harbor/harbor-common.sh
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Common Configuration"
################################################################################
. /opt/harbor/sahara-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${COMPONENT_SUBCOMPONET} Configuration"
################################################################################
: ${SAHARA_DB_USER:=sahara}
: ${SAHARA_DB_NAME:=sahara}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${CINDER_KEYSTONE_USER:=sahara}
: ${ADMIN_USER:="admin"}
: ${ADMIN_USER_DOMAIN:="default"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${COMPONENT_SUBCOMPONET}: Database"
################################################################################
/usr/bin/sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${COMPONENT_SUBCOMPONET}: Launching"
################################################################################
exec /usr/bin/sahara-engine --config-file /etc/sahara/sahara.conf --debug
