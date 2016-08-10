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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ACTIVATING DOMAIN SPECIFIC DRIVERS"
################################################################################
crudini --set $cfg identity domain_specific_drivers_enabled "true"
crudini --set $cfg identity domain_configurations_from_database "true"
