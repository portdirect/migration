#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SWIFT RINGS"
################################################################################
mkdir -p /etc/os-swift
mkdir -p /etc/swift-devices
for SWIFT_RING_CONFIG in /etc/swift-devices/*; do
   SWIFT_RING=$(echo "$SWIFT_RING_CONFIG" | rev | cut -d"/" -f1 | rev)
   sed 's/\\n/\n/g' $SWIFT_RING_CONFIG > /etc/os-swift/$SWIFT_RING.env
   sed '/^\s*$/d' -i /etc/os-swift/$SWIFT_RING.env
   sed -e 's/^/export /' -i /etc/os-swift/$SWIFT_RING.env
   source /etc/os-swift/$SWIFT_RING.env
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/config-swift.sh



CMD="/usr/bin/swift-account-server"
ARGS="/etc/swift/account-server.conf --verbose"
SWIFT_ACCOUNT_SVC_BIND_IP=$(ip -f inet -o addr show $SWIFT_ACCOUNT_SVC_BIND_DEV|cut -d\  -f 7 | cut -d/ -f 1)

check_required_vars \
    SWIFT_ACCOUNT_SVC_BIND_IP \
    SWIFT_ACCOUNT_SVC_BIND_PORT \
    SWIFT_ACCOUNT_SVC_DEVICES \
    SWIFT_ACCOUNT_SVC_MOUNT_CHECK \
    SWIFT_ACCOUNT_SVC_RING_DEVICES \
    SWIFT_ACCOUNT_SVC_RING_HOSTS \
    SWIFT_ACCOUNT_SVC_RING_MIN_PART_HOURS \
    SWIFT_ACCOUNT_SVC_RING_NAME \
    SWIFT_ACCOUNT_SVC_RING_PART_POWER \
    SWIFT_ACCOUNT_SVC_RING_REPLICAS \
    SWIFT_ACCOUNT_SVC_RING_WEIGHTS \
    SWIFT_ACCOUNT_SVC_RING_ZONES \
    SWIFT_DIR \
    SWIFT_USER


################################################################################
echo "${OS_DISTRO}: Swift: Account Server: Configuration"
################################################################################
cfg=/etc/swift/account-server.conf

crudini --set $cfg DEFAULT bind_ip "${SWIFT_ACCOUNT_SVC_BIND_IP}"
crudini --set $cfg DEFAULT bind_port "${SWIFT_ACCOUNT_SVC_BIND_PORT}"
crudini --set $cfg DEFAULT user "${SWIFT_USER}"
crudini --set $cfg DEFAULT swift_dir "${SWIFT_DIR}"
crudini --set $cfg DEFAULT devices "${SWIFT_ACCOUNT_SVC_DEVICES}"
crudini --set $cfg DEFAULT mount_check "${SWIFT_ACCOUNT_SVC_MOUNT_CHECK}"

crudini --set $cfg pipeline:main pipeline "healthcheck recon account-server"

crudini --set $cfg filter:recon use "egg:swift#recon"
crudini --set $cfg filter:recon recon_cache_path "/var/cache/swift"


################################################################################
echo "${OS_DISTRO}: Swift: Managing system users "
################################################################################

# Create swift user and group if they don't exist
id -u swift &>/dev/null || useradd --user-group swift

# Ensure proper ownership of the mount point directory structure
chown -R swift:swift /srv/node


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
