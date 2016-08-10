#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=component-common-vars
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${DEFAULT_REGION:="HarborOS"}

: ${DESIGNATE_API_SERVICE_HOSTNAME:="designate"}
: ${DESIGNATE_API_SERVICE_HOST:="${DESIGNATE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}

: ${DESIGNATE_DNS_SERVICE_HOST:="designate-dns.os-designate.svc.$OS_DOMAIN"}
: ${DESIGNATE_MDNS_SERVICE_HOST:="designate-mdns.os-designate.svc.$OS_DOMAIN"}

: ${DESIGNATE_POOL_ID:="794ccc2c-d751-44fe-b57f-8894c9f5c842"}
: ${DESIGNATE_POOL_NAMESERVERS_ID:="0f66b842-96c2-4189-93fc-1dc95a08b012"}
: ${DESIGNATE_POOL_TARGETS_ID:="f26e0b32-736f-4f0a-831b-039a415c481e"}
