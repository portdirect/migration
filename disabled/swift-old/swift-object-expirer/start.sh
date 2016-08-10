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
. /opt/harbor/config-swift.sh
. /opt/harbor/config-swift-object.sh

CMD="/usr/bin/swift-object-expirer"
ARGS="/etc/swift/object-expirer.conf --verbose"

################################################################################
echo "${OS_DISTRO}: Swift: Building Ring: Account (${SWIFT_ACCOUNT_SVC_RING_NAME}) "
################################################################################
python /opt/harbor/build-swift-ring.py \
    -f ${SWIFT_ACCOUNT_SVC_RING_NAME} \
    -p ${SWIFT_ACCOUNT_SVC_RING_PART_POWER} \
    -r ${SWIFT_ACCOUNT_SVC_RING_REPLICAS} \
    -m ${SWIFT_ACCOUNT_SVC_RING_MIN_PART_HOURS} \
    -H ${SWIFT_ACCOUNT_SVC_RING_HOSTS} \
    -w ${SWIFT_ACCOUNT_SVC_RING_WEIGHTS} \
    -d ${SWIFT_ACCOUNT_SVC_RING_DEVICES} \
    -z ${SWIFT_ACCOUNT_SVC_RING_ZONES}

################################################################################
echo "${OS_DISTRO}: Swift: Launching ($CMD $ARGS) "
################################################################################
exec $CMD $ARGS
