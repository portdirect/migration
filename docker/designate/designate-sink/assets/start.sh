#!/bin/bash
set -o errexit
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
. /opt/harbor/config-designate.sh
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars DESIGNATE_DB_NAME DESIGNATE_POOL_DB_NAME


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${DESIGNATE_POOL_DB_NAME}
fail_unless_db ${DESIGNATE_DB_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring Sink"
################################################################################
. /opt/harbor/designate/config-sink.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/sh -c "exec /usr/bin/designate-sink --debug" designate
