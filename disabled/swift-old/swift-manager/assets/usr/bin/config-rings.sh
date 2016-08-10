#!/bin/sh

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



echo "${OS_DISTRO}: Storage Config: Glusterfs"
echo "Now we have the master node provisioned, and two other hosts up we next"
echo "setup storage, for subsquent systems to use"

HOSTNAME=$(hostname -s)
HARBOROS_ETCD_ROOT=/harboros
SWIFT_ROLE=swift


GLUSTER_ROLE=glusterfs






list_swift_devs () {
  COUNTER=0
  for DISC_TYPE in ssd hdd; do
    etcdctl --endpoint ${CORE_ETCD_ENDPOINT} ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl --endpoint ${CORE_ETCD_ENDPOINT} get ${ETCD_KEY})
          if [ "${ROLE}" == "${SWIFT_ROLE}" ]; then
            ETCD_KEY=${ETCD_KEY#"${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/"}
            IFS='/' read SWIFT_HOST SWIFT_DEVICE <<< "${ETCD_KEY%/*}"
            SWIFT_HOST_IP=$(etcdctl --endpoint ${CORE_ETCD_ENDPOINT} get ${HARBOROS_ETCD_ROOT}/storage/${GLUSTER_ROLE}/${SWIFT_HOST})
            echo "$SWIFT_HOST_IP"
            echo "$SWIFT_DEVICE"
          fi
        done
  done
}






echo "#########################################################################"
echo "HarborOS: Storage Config: Swift: Listing devices"
echo "#########################################################################"

list_swift_devs

RING_PART_POWER=${SWIFT_OBJECT_SVC_RING_PART_POWER}
RING_REPLICAS=${SWIFT_OBJECT_SVC_RING_REPLICAS}
MIN_PART_HOURS=${SWIFT_OBJECT_SVC_RING_MIN_PART_HOURS}



init_swift_rings () {
  SWIFT_STARTING_PORT=6000
  RING_PORT=${SWIFT_STARTING_PORT}
  for SWIFT_RING in OBJECT CONTAINER ACCOUNT; do
    source /etc/os-container.env
    RING_HOSTS=""
    RING_DEVICES=""
    RING_WEIGHTS=""
    RING_ZONES=""
    RING_WEIGHT=1
    RING_DEVICE_COUNT=1
    for DISC_TYPE in ssd hdd; do
      while read ETCD_KEY; do
            ROLE=$(etcdctl --endpoint ${CORE_ETCD_ENDPOINT} get ${ETCD_KEY})
            if [ "${ROLE}" == "${SWIFT_ROLE}" ]; then
              ETCD_KEY=${ETCD_KEY#"${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/"}
              IFS='/' read SWIFT_HOST SWIFT_DEVICE <<< "${ETCD_KEY%/*}"
              SWIFT_HOST_IP=$(etcdctl --endpoint ${CORE_ETCD_ENDPOINT} get ${HARBOROS_ETCD_ROOT}/storage/${GLUSTER_ROLE}/${SWIFT_HOST})
              SWIFT_WEIGHT=${RING_WEIGHT}
              SWIFT_ZONE=${COUNTER}
              RING_HOSTS="${SWIFT_HOST_IP}:${RING_PORT},${RING_HOSTS%,}"
              RING_DEVICES="${SWIFT_DEVICE},${RING_DEVICES%,}"
              RING_WEIGHTS="${SWIFT_WEIGHT},${RING_WEIGHTS%,}"
              # This is the other way round so the master node is the 1st ring
              RING_ZONES="${RING_ZONES#,},${RING_DEVICE_COUNT}"
              RING_DEVICE_COUNT=$((RING_DEVICE_COUNT+1))
            fi
          done <<< "$(echo -e "$(etcdctl --endpoint ${CORE_ETCD_ENDPOINT} ls --sort -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role)")"
    done
    RING_PORT=$((RING_PORT+1))

    SWIFT_RING_NAME=$(echo ${SWIFT_RING} | tr '[:upper:]' '[:lower:]')
    echo "SWIFT_${SWIFT_RING}_SVC_RING_HOSTS=${RING_HOSTS}" > /tmp/${SWIFT_RING_NAME}.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_DEVICES=${RING_DEVICES}" >> /tmp/${SWIFT_RING_NAME}.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_WEIGHTS=${RING_WEIGHTS}" >> /tmp/${SWIFT_RING_NAME}.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_ZONES=${RING_ZONES}" >> /tmp/${SWIFT_RING_NAME}.env
    RING_DEVICE_COUNT=$((RING_DEVICE_COUNT-1))
    echo "SWIFT_${SWIFT_RING}_SVC_RING_DEVICE_COUNT=${RING_DEVICE_COUNT}" >> /tmp/${SWIFT_RING_NAME}.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_PART_POWER=${RING_PART_POWER}" >> /tmp/${SWIFT_RING_NAME}.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_REPLICAS=${RING_REPLICAS}" >> /tmp/${SWIFT_RING_NAME}.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_MIN_PART_HOURS=${MIN_PART_HOURS}" >> /tmp/${SWIFT_RING_NAME}.env
    echo $SWIFT_RING_NAME
    cat /tmp/${SWIFT_RING_NAME}.env
  done
}

echo "######################################################################"
echo "HarborOS: Swift: Initializing swift ring config"
echo "######################################################################"
init_swift_rings





echo "######################################################################"
echo "HarborOS: Swift: Uploading the ring configs as a kubenetes service-secret"
echo "######################################################################"
mkdir -p /etc/harbor/
cat > /etc/harbor/swift-devices.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: swift-devices
  namespace: os-swift
type: Opaque
data:
  object: $( cat /tmp/object.env | base64 --wrap=0 )
  container: $( cat /tmp/container.env | base64 --wrap=0 )
  account: $( cat /tmp/account.env | base64 --wrap=0 )
EOF
kubectl --server="${KUBE_ENDPOINT}" delete -f /etc/harbor/swift-devices.yaml || true
kubectl --server="${KUBE_ENDPOINT}" create -f /etc/harbor/swift-devices.yaml
