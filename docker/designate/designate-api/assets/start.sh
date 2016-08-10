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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting api to listen on 127.0.0.1:8080"
################################################################################
export cfg=/etc/designate/designate.conf
crudini --set $cfg service:api api_host "127.0.0.1"
crudini --set $cfg service:api api_port "9981"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Pool Info"
################################################################################
n=0
until [ $n -ge 36 ]
do
  su -s /bin/sh -c "/usr/bin/designate-manage pool show_config" designate > /tmp/designate-pool
  if grep -q "powerdns" /tmp/designate-pool ; then
      echo "powerdns config loaded"
      rm -f /tmp/designate-pool
      break
  else
      echo "powerdns not found"
      rm -f /tmp/designate-pool
  fi
   n=$[$n+1]
   ################################################################################
   echo "${OS_DISTRO}: Waiting for Powerdns config to be loaded into db attempt $n of 36"
   ################################################################################
   sleep 5
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/sh -c "exec /usr/bin/designate-api --debug" designate
