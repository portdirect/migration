#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=etcd-leader-election
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

HOSTNAME=$(hostname -s)
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars ETCDCTL_ENDPOINT OS_DISTRO OPENSTACK_COMPONENT HOSTNAME

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Running Election Script"
################################################################################
while true; do
    ( etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/current-leader && \
      echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: We did not become the leader this round" && sleep 60 ) || \
    ( etcdctl --endpoint ${ETCDCTL_ENDPOINT} mk /${OS_DISTRO}/${OPENSTACK_COMPONENT}/current-leader "${HOSTNAME}" --ttl 120 && \
      echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: We became the leader during this round" && sleep 30 )
done
