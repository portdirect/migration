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


rm -rf /var/lib/docker/*
/opt/harbor/nova-compute/dind.sh &
sleep 2s
################################################################################
echo "${OS_DISTRO}: Nova-Compute: Starting"
################################################################################
exec /usr/bin/nova-compute --config-file /etc/nova/nova.conf --debug
