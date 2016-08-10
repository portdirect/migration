#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=ring-builder
SWIFT_RING=container
SWIFT_RING_PORT=6001
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ${SWIFT_RING}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ${SWIFT_RING}: Building Ring"
################################################################################
cd /etc/swift
HARBOROS_ETCD_ROOT=/harboros
SWIFT_ROLE=swift
SWIFT_DOMAIN="${SWIFT_RING}.storage.node.local"
swift-ring-builder ${SWIFT_RING}.builder create 10 3 1
for DISC_TYPE in ssd hdd; do
  etcdctl --endpoint ${CORE_ETCD_ENDPOINT} ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role | \
      while read ETCD_KEY; do
        ROLE=$(etcdctl --endpoint ${CORE_ETCD_ENDPOINT} get ${ETCD_KEY})
        if [ "${ROLE}" == "${SWIFT_ROLE}" ]; then
          ETCD_KEY=${ETCD_KEY#"${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/"}
          IFS='/' read SWIFT_HOST SWIFT_DEVICE <<< "${ETCD_KEY%/*}"

          swift-ring-builder ${SWIFT_RING}.builder add \
            --region 1 \
            --zone 1 \
            --ip $SWIFT_HOST.$SWIFT_DOMAIN \
            --port ${SWIFT_RING_PORT} \
            --device $SWIFT_DEVICE \
            --weight 100 || true
        fi
      done
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ${SWIFT_RING}: DISPLAYING RING"
################################################################################
swift-ring-builder ${SWIFT_RING}.builder


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ${SWIFT_RING}: REBLANCING RING"
################################################################################
swift-ring-builder ${SWIFT_RING}.builder rebalance
