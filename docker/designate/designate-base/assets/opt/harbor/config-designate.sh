#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=common-config
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
. /opt/harbor/designate/common-vars.sh
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DESGINATE"
################################################################################
# Designate Settings
: ${DESIGNATE_API_SERVICE_HOSTNAME:="designate"}
: ${DESIGNATE_API_SERVICE_HOST:="${DESIGNATE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}

: ${DESIGNATE_DNS_SERVICE_HOST:="designate-dns.os-designate.svc.$OS_DOMAIN"}
: ${DESIGNATE_MDNS_SERVICE_HOST:="designate-mdns.os-designate.svc.$OS_DOMAIN"}

: ${DESIGNATE_POOL_ID:="794ccc2c-d751-44fe-b57f-8894c9f5c842"}
: ${DESIGNATE_POOL_NAMESERVERS_ID:="0f66b842-96c2-4189-93fc-1dc95a08b012"}
: ${DESIGNATE_POOL_TARGETS_ID:="f26e0b32-736f-4f0a-831b-039a415c481e"}

export cfg=/etc/designate/designate.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Checking Env"
################################################################################


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/designate/config-keystone.sh
. /opt/harbor/designate/config-database.sh
. /opt/harbor/designate/config-pool-database.sh
. /opt/harbor/designate/config-rabbitmq.sh
. /opt/harbor/designate/config-neutron.sh
. /opt/harbor/designate/config-pools.sh
. /opt/harbor/designate/config-api.sh
