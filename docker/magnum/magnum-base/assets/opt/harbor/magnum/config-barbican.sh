#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=barbican
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${DEFAULT_REGION:="HarborOS"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg DEFAULT_REGION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
#crudini --set $cfg certificates cert_manager_type "barbican"

MAGNUM_LOCAL_CERT_DIR=${MAGNUM_LOCAL_CERT_DIR:-/var/lib/magnum/certificates/}
if [[ ! -d $MAGNUM_LOCAL_CERT_DIR ]]; then
    mkdir -p $MAGNUM_LOCAL_CERT_DIR
    chown magnum $MAGNUM_LOCAL_CERT_DIR
fi
crudini --set $cfg certificates storage_path "$MAGNUM_LOCAL_CERT_DIR"
crudini --set $cfg certificates cert_manager_type "local"
