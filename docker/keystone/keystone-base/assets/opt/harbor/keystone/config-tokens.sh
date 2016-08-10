#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=tokens
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TOKENS"
################################################################################
crudini --set $cfg token provider "fernet"
crudini --set $cfg token driver "sql"

###############################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COPYING TOKENS INTO PLACE"
################################################################################
mkdir -p /etc/keystone/fernet-keys
cp /etc/os-fernet/* /etc/keystone/fernet-keys/
chown -R keystone:keystone /etc/keystone/fernet-keys
