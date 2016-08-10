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

SWIFT_OBJECT_SVC_BIND_IP=$(ip -f inet -o addr show $SWIFT_OBJECT_SVC_BIND_DEV|cut -d\  -f 7 | cut -d/ -f 1)


check_required_vars \
    SWIFT_CONTAINER_SVC_RING_DEVICES \
    SWIFT_CONTAINER_SVC_RING_HOSTS \
    SWIFT_CONTAINER_SVC_RING_MIN_PART_HOURS \
    SWIFT_CONTAINER_SVC_RING_NAME \
    SWIFT_CONTAINER_SVC_RING_PART_POWER \
    SWIFT_CONTAINER_SVC_RING_REPLICAS \
    SWIFT_CONTAINER_SVC_RING_WEIGHTS \
    SWIFT_CONTAINER_SVC_RING_ZONES \
    SWIFT_DIR \
    SWIFT_OBJECT_SVC_BIND_IP \
    SWIFT_OBJECT_SVC_BIND_PORT \
    SWIFT_OBJECT_SVC_DEVICES \
    SWIFT_OBJECT_SVC_MOUNT_CHECK \
    SWIFT_OBJECT_SVC_PIPELINE \
    SWIFT_OBJECT_SVC_RING_DEVICES \
    SWIFT_OBJECT_SVC_RING_HOSTS \
    SWIFT_OBJECT_SVC_RING_MIN_PART_HOURS \
    SWIFT_OBJECT_SVC_RING_NAME \
    SWIFT_OBJECT_SVC_RING_PART_POWER \
    SWIFT_OBJECT_SVC_RING_REPLICAS \
    SWIFT_OBJECT_SVC_RING_WEIGHTS \
    SWIFT_OBJECT_SVC_RING_ZONES \
    SWIFT_USER

################################################################################
echo "${OS_DISTRO}: Swift: Object: Base Configuration"
################################################################################

cfg=/etc/swift/object-server.conf

crudini --set $cfg DEFAULT bind_ip "${SWIFT_OBJECT_SVC_BIND_IP}"
crudini --set $cfg DEFAULT bind_port "${SWIFT_OBJECT_SVC_BIND_PORT}"
crudini --set $cfg DEFAULT user "${SWIFT_USER}"
crudini --set $cfg DEFAULT swift_dir "${SWIFT_DIR}"
crudini --set $cfg DEFAULT devices "${SWIFT_OBJECT_SVC_DEVICES}"
crudini --set $cfg DEFAULT mount_check "${SWIFT_OBJECT_SVC_MOUNT_CHECK}"

crudini --set $cfg pipeline:main pipeline "healthcheck recon object-server"

crudini --set $cfg filter:recon use "egg:swift#recon"
crudini --set $cfg filter:recon recon_cache_path /var/cache/swift
crudini --set $cfg filter:recon recon_lock_path /var/lock


crudini --set $cfg object-expirer

# Create swift user and group if they don't exist
id -u swift &>/dev/null || useradd --user-group swift

################################################################################
echo "${OS_DISTRO}: Swift: Storage dir"
################################################################################
mkdir -p /srv/node
chown -R swift:swift /srv/node

################################################################################
echo "${OS_DISTRO}: Swift: Setting up cache dir"
################################################################################
mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift


################################################################################
echo "${OS_DISTRO}: Swift: Building Ring: Object (${SWIFT_OBJECT_SVC_RING_NAME}) "
################################################################################

python /opt/harbor/build-swift-ring.py \
    -f ${SWIFT_OBJECT_SVC_RING_NAME} \
    -p ${SWIFT_OBJECT_SVC_RING_PART_POWER} \
    -r ${SWIFT_OBJECT_SVC_RING_REPLICAS} \
    -m ${SWIFT_OBJECT_SVC_RING_MIN_PART_HOURS} \
    -H ${SWIFT_OBJECT_SVC_RING_HOSTS} \
    -w ${SWIFT_OBJECT_SVC_RING_WEIGHTS} \
    -d ${SWIFT_OBJECT_SVC_RING_DEVICES} \
    -z ${SWIFT_OBJECT_SVC_RING_ZONES}


################################################################################
echo "${OS_DISTRO}: Swift: Building Ring: Container (${SWIFT_CONTAINER_SVC_RING_NAME}) "
################################################################################

python /opt/harbor/build-swift-ring.py \
    -f ${SWIFT_CONTAINER_SVC_RING_NAME} \
    -p ${SWIFT_CONTAINER_SVC_RING_PART_POWER} \
    -r ${SWIFT_CONTAINER_SVC_RING_REPLICAS} \
    -m ${SWIFT_CONTAINER_SVC_RING_MIN_PART_HOURS} \
    -H ${SWIFT_CONTAINER_SVC_RING_HOSTS} \
    -w ${SWIFT_CONTAINER_SVC_RING_WEIGHTS} \
    -d ${SWIFT_CONTAINER_SVC_RING_DEVICES} \
    -z ${SWIFT_CONTAINER_SVC_RING_ZONES}
