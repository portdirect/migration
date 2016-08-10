#!/bin/bash
set -e
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
. /opt/harbor/config-nova.sh
. /opt/harbor/config-nova-compute.sh


#/usr/bin/lxd --logfile=/var/log/lxd.log --debug &

INITIAL_SLEEP_TIME=20
################################################################################
echo "${OS_DISTRO}: Nova-API: Sleeping for $INITIAL_SLEEP_TIME seconds"
################################################################################
sleep 20


################################################################################
echo "${OS_DISTRO}: Nova-Compute: Starting"
################################################################################
exec /usr/bin/nova-compute --config-file /etc/nova/nova.conf --debug
