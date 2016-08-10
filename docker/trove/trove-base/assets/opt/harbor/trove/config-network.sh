#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=ceilometer
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
check_required_vars cfg ETCDCTL_ENDPOINT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting TROVE_NET_ID"
################################################################################
TROVE_NET_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/management_network_id)"
check_required_vars TROVE_NET_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting NEtworking COnfig"
################################################################################
crudini --set $cfg DEFAULT network_label_regex ".*"
crudini --set $cfg DEFAULT ip_regex ".*"
crudini --set $cfg DEFAULT blacklist_regex "^10.0.1.*"
crudini --set $cfg DEFAULT default_neutron_networks "${TROVE_NET_ID}"
crudini --set $cfg DEFAULT network_driver "trove.network.neutron.NeutronDriver"
