#!/bin/bash

OPENSTACK_COMPONENT=freeipa
OPENSTACK_SUBCOMPONENT=status

source /etc/os-common/common.env

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Status"
################################################################################
STATUS=$(etcdctl get /${OS_DISTRO}/freeipa/status)
if [ "$STATUS" != "UP" ]
then
  echo "Service is not marked as UP in etcd at /${OS_DISTRO}/freeipa/status, exiting."
  exit 1
else
  echo "Service is marked as UP in etcd at /${OS_DISTRO}/freeipa/status."
  exit 0
fi
