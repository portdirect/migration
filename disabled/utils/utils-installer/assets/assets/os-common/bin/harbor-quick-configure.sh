#!/bin/bash
action=restart
systemctl ${action} cockpit


# firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -s 10.96.0.0/12 -p tcp --dport 53 -j ACCEPT
# firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -s 10.96.0.0/12 -p udp --dport 53 -j ACCEPT
# firewall-cmd --permanent --direct --query-rule ipv4 filter INPUT 0 -s 10.96.0.0/12 -p tcp --dport 53 -j ACCEPT
# firewall-cmd --permanent --direct --query-rule ipv4 filter INPUT 0 -s 10.96.0.0/12 -p udp --dport 53 -j ACCEPT



action=restart
echo "#########################################################################"
echo "${OS_DISTRO}: starting initial services"
echo "#########################################################################"
echo "${OS_DISTRO}: starting freeipa"
systemctl ${action} freeipa
systemctl ${action} skydns-freeipa
systemctl ${action} skydns
echo "#########################################################################"
echo "${OS_DISTRO}: starting pxe"
systemctl ${action} pxe
echo "#########################################################################"





echo "Please boot 2 nodes via pxe and wait for them to finish being provisioned"







echo "#########################################################################"
echo "${OS_DISTRO}: Storage Config: Glusterfs"
echo "#########################################################################"

echo "Now we have the master node provisioned, and two other hosts up we next"
echo "setup storage, for subsquent systems to use"

HOSTNAME=$(hostname -s)
OS_DOMAIN=port.direct
HARBOROS_ETCD_ROOT=/harboros
GLUSTER_ROLE=glusterfs
GLUSTER_DOMAIN=os-glusterfs.$(hostname -d)
SWIFT_DOMAIN=$GLUSTER_DOMAIN
source /etc/os-glusterfs/os-glusterfs.env



label_gluster_nodes () {
  echo "#########################################################################"
  echo "${OS_DISTRO}: Storage Config: Labeling Glusterfs Nodes"
  echo "#########################################################################"
  KUBE_NODES=$(kubectl get nodes --no-headers| awk -F ' ' '{print $1}')
  for KUBE_NODE in $KUBE_NODES
  do
    kubectl label --overwrite node $KUBE_NODE glusterfs=true
  done
}

label_gluster_devs () {
  echo "#########################################################################"
  echo "${OS_DISTRO}: Storage Config: Labeling Glusterfs Devices"
  echo "#########################################################################"
  for DISC_TYPE in hdd; do
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "none" ]; then
            etcdctl set ${ETCD_KEY} ${GLUSTER_ROLE}
          fi
        done
  done
}

list_gluster_devs () {
  echo "#########################################################################"
  echo "${OS_DISTRO}: Storage Config: Listing Glusterfs Devices"
  echo "#########################################################################"
  for DISC_TYPE in ssd hdd; do
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "${GLUSTER_ROLE}" ]; then
            echo ${ETCD_KEY%/*}
          fi
        done
  done
}

label_gluster_nodes
label_gluster_devs
list_gluster_devs




echo "#########################################################################"
echo "${OS_DISTRO}: Storage Config: Swift"
echo "#########################################################################"
SWIFT_ROLE=swift
source /etc/os-swift/os-swift.env


label_swift_nodes () {
  echo "#########################################################################"
  echo "${OS_DISTRO}: Storage Config: Swift: Labeling nodes"
  echo "#########################################################################"
  KUBE_NODES=$(kubectl get nodes --no-headers| awk -F ' ' '{print $1}')
  for KUBE_NODE in $KUBE_NODES
  do
    echo "${OS_DISTRO}: Storage Config: Swift: $KUBE_NODE"
    /usr/local/bin/kubectl label --overwrite node $KUBE_NODE swift=true
      echo "${OS_DISTRO}: Storage Config: Swift: proxy"
    /usr/local/bin/kubectl label --overwrite node $KUBE_NODE swift-proxy=true
      echo "${OS_DISTRO}: Storage Config: Swift: storage"
    /usr/local/bin/kubectl label --overwrite node $KUBE_NODE swift-storage=true
  done
}

label_swift_devs () {
  echo "#########################################################################"
  echo "${OS_DISTRO}: Storage Config: Swift: Labeling devices"
  echo "#########################################################################"
  for DISC_TYPE in hdd; do
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "none" ]; then
            etcdctl set ${ETCD_KEY} ${SWIFT_ROLE}
          fi
        done
  done
}

list_swift_devs () {
  echo "#########################################################################"
  echo "${OS_DISTRO}: Storage Config: Swift: Listing devices"
  echo "#########################################################################"
  for DISC_TYPE in ssd hdd; do
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "${SWIFT_ROLE}" ]; then
            ETCD_KEY=${ETCD_KEY#"${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/"}
            IFS='/' read SWIFT_HOST SWIFT_DEVICE <<< "${ETCD_KEY%/*}"
            echo "$SWIFT_HOST.$SWIFT_DOMAIN/$SWIFT_DEVICE"
          fi
        done
  done
}

label_swift_nodes
label_swift_devs
list_swift_devs
















manage_gluster_devs () {
    STORAGE_TYPE=gluster
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/nodes | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "none" ]; then
            ETCD_KEY=${ETCD_KEY#"$HARBOROS_ETCD_ROOT/nodes/"}
            NODE=${ETCD_KEY%/*}
            echo "#########################################################################"
            echo "${OS_DISTRO}: Storage: $STORAGE_TYPE: $NODE.$OS_DOMAIN: device prep"
            echo "#########################################################################"
            harbor-swarm run --net=host \
                  --privileged \
                  -v /dev:/dev \
                  -v /tmp/harbor:/tmp/harbor \
                  --env-file /etc/os-glusterfs/os-glusterfs.env \
                  -e constraint:node==${NODE}.${OS_DOMAIN} \
                  -e SCRIPT=${STORAGE_TYPE} \
                  registry.harboros.net:3040/harboros/utils-discs:latest
            echo "#########################################################################"
            echo "${OS_DISTRO}: Storage: $STORAGE_TYPE: $NODE.$OS_DOMAIN: device listing"
            echo "#########################################################################"
            harbor-swarm run --net=host \
                  --privileged \
                  -v /dev:/dev \
                  -e constraint:node==${NODE}.${OS_DOMAIN} \
                  registry.harboros.net:3040/harboros/utils-discs:latest lsblk
          fi
        done
}
manage_gluster_devs

manage_swift_devs () {
    STORAGE_TYPE=swift
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/nodes | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "none" ]; then
            ETCD_KEY=${ETCD_KEY#"$HARBOROS_ETCD_ROOT/nodes/"}
            NODE=${ETCD_KEY%/*}
            echo "#########################################################################"
            echo "${OS_DISTRO}: Storage: $STORAGE_TYPE: $NODE.$OS_DOMAIN: device prep"
            echo "#########################################################################"
            harbor-swarm run --net=host \
                  --privileged \
                  -v /dev:/dev \
                  -v /tmp/harbor:/tmp/harbor \
                  --env-file /etc/os-glusterfs/os-glusterfs.env \
                  -e constraint:node==${NODE}.${OS_DOMAIN} \
                  -e SCRIPT=${STORAGE_TYPE} \
                  registry.harboros.net:3040/harboros/utils-discs:latest
            echo "#########################################################################"
            echo "${OS_DISTRO}: Storage: $STORAGE_TYPE: $NODE.$OS_DOMAIN: device listing"
            echo "#########################################################################"
            harbor-swarm run --net=host \
                  --privileged \
                  -v /dev:/dev \
                  -e constraint:node==${NODE}.${OS_DOMAIN} \
                  registry.harboros.net:3040/harboros/utils-discs:latest lsblk
          fi
        done
}
manage_swift_devs

mount_devs () {
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/nodes | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "none" ]; then
            ETCD_KEY=${ETCD_KEY#"$HARBOROS_ETCD_ROOT/nodes/"}
            NODE=${ETCD_KEY%/*}
            echo $NODE.$OS_DOMAIN
            echo "#########################################################################"
            echo "${OS_DISTRO}: Storage: $NODE.$OS_DOMAIN: Triggering remount"
            echo "#########################################################################"
            harbor-swarm run --net=host \
                  --privileged \
                  -v /lib/modules:/lib/modules:ro \
                  -v /run/lvm:/run/lvm \
                  -v /dev:/dev \
                  -v /tmp/harbor:/tmp/harbor \
                  --env-file /etc/os-glusterfs/os-glusterfs.env \
                  -e constraint:node==${NODE}.${OS_DOMAIN} \
                  -e SCRIPT=mount \
                  registry.harboros.net:3040/harboros/utils-discs:latest
          fi
        done
}
mount_devs



echo "######################################################################"
echo "HarborOS: Gluster:"
echo "######################################################################"
GLUSTER_VOLUMES=/tmp/gluster-volumes
cat > ${GLUSTER_VOLUMES} <<EOF
os-cinder 100G
os-manila 100G
EOF

populate_gluster_volumes () {
  while read GLUSTER_VOLUME; do
    GLUSTER_VOLUME_NAME=$(echo ${GLUSTER_VOLUME} | awk '{print $1}')
    GLUSTER_VOLUME_SIZE=$(echo ${GLUSTER_VOLUME} | awk '{print $2}')
    echo "######################################################################"
    echo "HarborOS: Gluster: ${GLUSTER_VOLUME_NAME}"
    echo "######################################################################"
    populate_gluster_volume () {
        etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/nodes | grep role | \
            while read ETCD_KEY; do
              ROLE=$(etcdctl get ${ETCD_KEY})
              if [ "${ROLE}" == "none" ]; then
                ETCD_KEY=${ETCD_KEY#"$HARBOROS_ETCD_ROOT/nodes/"}
                NODE=${ETCD_KEY%/*}
                echo "#########################################################################"
                echo "${OS_DISTRO}: Gluster: $NODE.$OS_DOMAIN: Prepping volume ${GLUSTER_VOLUME_NAME}"
                echo "#########################################################################"
                harbor-swarm run --net=host \
                      --privileged \
                      -v /run/lvm:/run/lvm \
                      -v /dev:/dev \
                      -v /tmp/harbor:/tmp/harbor \
                      --env-file /etc/os-glusterfs/os-glusterfs.env \
                      -e constraint:node==${NODE}.${OS_DOMAIN} \
                      -e GLUSTER_VOLUME_NAME=${GLUSTER_VOLUME_NAME} \
                      -e GLUSTER_VOLUME_SIZE=${GLUSTER_VOLUME_SIZE} \
                      -e SCRIPT=populate-gluster \
                      registry.harboros.net:3040/harboros/utils-discs:latest
                echo "#########################################################################"
                echo "${OS_DISTRO}: Gluster: $NODE.$OS_DOMAIN: Listing Block devices"
                echo "#########################################################################"
                harbor-swarm run --net=host \
                      --privileged \
                      -v /dev:/dev \
                      -e constraint:node==${NODE}.${OS_DOMAIN} \
                      registry.harboros.net:3040/harboros/utils-discs:latest lsblk
              fi
            done
    }
    populate_gluster_volume
    sleep 5
  done <${GLUSTER_VOLUMES}
}
populate_gluster_volumes



init_gluster_nodes () {
    echo "######################################################################"
    echo "HarborOS: Gluster: Initializing glusterfs config"
    echo "######################################################################"
    NODE_COUNT=0
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/nodes | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          if [ "${ROLE}" == "none" ]; then
            NODE_COUNT=$(($NODE_COUNT+1))
            echo $NODE_COUNT > /tmp/gluster-node-count
          fi
        done
    NODE_COUNT=$(cat /tmp/gluster-node-count)
    echo "######################################################################"
    echo "HarborOS: Gluster: $NODE_COUNT nodes found"
    echo "######################################################################"
    sed -i "s/.*INITIAL_GLUSTER_HOSTS.*/INITIAL_GLUSTER_HOSTS=$NODE_COUNT/g" /etc/os-glusterfs/os-glusterfs.env
    INITIAL_GLUSTER_HOSTS=$NODE_COUNT
}
init_gluster_nodes


echo "######################################################################"
echo "HarborOS: Gluster: Starting Service"
echo "######################################################################"
/var/usrlocal/bin/os-glusterfs-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-glusterfs/kube/os-glusterfs_service.yaml --namespace=os-glusterfs
/usr/local/bin/kubectl delete -f /etc/os-glusterfs/kube/os-glusterfs_endpoints.yaml --namespace=os-glusterfs
/usr/local/bin/kubectl delete -f /etc/os-glusterfs/kube/os-glusterfs_daemonset.yaml --namespace=os-glusterfs
/usr/local/bin/kubectl delete -f /etc/os-glusterfs/kube/os-glusterfs_secrets.yaml --namespace=os-glusterfs


/usr/local/bin/kubectl create -f /etc/os-glusterfs/kube/os-glusterfs_namespace.yaml
/usr/local/bin/kubectl create -f /etc/os-glusterfs/kube/os-glusterfs_secrets.yaml --namespace=os-glusterfs
/usr/local/bin/kubectl create -f /etc/os-glusterfs/kube/os-glusterfs_daemonset.yaml --namespace=os-glusterfs

/usr/local/bin/kubectl create -f /etc/os-glusterfs/kube/os-glusterfs_service.yaml --namespace=os-glusterfs
/usr/local/bin/kubectl create -f /etc/os-glusterfs/kube/os-glusterfs_endpoints.yaml --namespace=os-glusterfs



init_swift_rings () {
  echo "######################################################################"
  echo "HarborOS: Swift: Initializing swift ring config"
  echo "######################################################################"
  SWIFT_STARTING_PORT=6000
  RING_PORT=${SWIFT_STARTING_PORT}
  for SWIFT_RING in OBJECT CONTAINER ACCOUNT; do
    RING_HOSTS=""
    RING_DEVICES=""
    RING_WEIGHTS=""
    RING_ZONES=""
    RING_WEIGHT=1
    RING_DEVICE_COUNT=1
    for DISC_TYPE in ssd hdd; do
      while read ETCD_KEY; do
            ROLE=$(etcdctl get ${ETCD_KEY})
            if [ "${ROLE}" == "${SWIFT_ROLE}" ]; then
              ETCD_KEY=${ETCD_KEY#"${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/"}
              IFS='/' read SWIFT_HOST SWIFT_DEVICE <<< "${ETCD_KEY%/*}"
              SWIFT_HOST=$SWIFT_HOST.$SWIFT_DOMAIN
              SWIFT_HOST=$(ping -c 1 ${SWIFT_HOST} | gawk -F '[()]' '/PING/{print $2}')
              SWIFT_WEIGHT=${RING_WEIGHT}
              SWIFT_ZONE=${COUNTER}
              RING_HOSTS="${SWIFT_HOST}:${RING_PORT},${RING_HOSTS%,}"
              RING_DEVICES="${SWIFT_DEVICE},${RING_DEVICES%,}"
              RING_WEIGHTS="${SWIFT_WEIGHT},${RING_WEIGHTS%,}"
              # This is the other way round so the master node is the 1st ring
              RING_ZONES="${RING_ZONES#,},${RING_DEVICE_COUNT}"
              RING_DEVICE_COUNT=$((RING_DEVICE_COUNT+1))
            fi
          done <<< "$(echo -e "$(etcdctl ls --sort -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE} | grep role)")"
    done
    RING_PORT=$((RING_PORT+1))

    echo "SWIFT_${SWIFT_RING}_SVC_RING_HOSTS=${RING_HOSTS}"
    sed -i "s/.*SWIFT_${SWIFT_RING}_SVC_RING_HOSTS.*/SWIFT_${SWIFT_RING}_SVC_RING_HOSTS=${RING_HOSTS}/g" /etc/os-swift/os-swift.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_DEVICES=${RING_DEVICES}"
    sed -i "s/.*SWIFT_${SWIFT_RING}_SVC_RING_DEVICES.*/SWIFT_${SWIFT_RING}_SVC_RING_DEVICES=${RING_DEVICES}/g" /etc/os-swift/os-swift.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_WEIGHTS=${RING_WEIGHTS}"
    sed -i "s/.*SWIFT_${SWIFT_RING}_SVC_RING_WEIGHTS.*/SWIFT_${SWIFT_RING}_SVC_RING_WEIGHTS=${RING_WEIGHTS}/g" /etc/os-swift/os-swift.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_ZONES=${RING_ZONES}"
    sed -i "s/.*SWIFT_${SWIFT_RING}_SVC_RING_ZONES.*/SWIFT_${SWIFT_RING}_SVC_RING_ZONES=${RING_ZONES}/g" /etc/os-swift/os-swift.env
    RING_DEVICE_COUNT=$((RING_DEVICE_COUNT-1))
    echo "SWIFT_${SWIFT_RING}_SVC_RING_DEVICE_COUNT=${RING_DEVICE_COUNT}"
    echo "SWIFT_${SWIFT_RING}_SVC_RING_PART_POWER=${RING_PART_POWER}"
    sed -i "s/.*SWIFT_${SWIFT_RING}_SVC_RING_PART_POWER.*/SWIFT_${SWIFT_RING}_SVC_RING_PART_POWER=${RING_PART_POWER}/g" /etc/os-swift/os-swift.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_REPLICAS=${RING_REPLICAS}"
    sed -i "s/.*SWIFT_${SWIFT_RING}_SVC_RING_REPLICAS.*/SWIFT_${SWIFT_RING}_SVC_RING_REPLICAS=${RING_REPLICAS}/g" /etc/os-swift/os-swift.env
    echo "SWIFT_${SWIFT_RING}_SVC_RING_MIN_PART_HOURS=${MIN_PART_HOURS}"
    sed -i "s/.*SWIFT_${SWIFT_RING}_SVC_RING_MIN_PART_HOURS.*/SWIFT_${SWIFT_RING}_SVC_RING_MIN_PART_HOURS=${MIN_PART_HOURS}/g" /etc/os-swift/os-swift.env
  done
}


echo "######################################################################"
echo "HarborOS: Swift: Initialise the ring"
echo "######################################################################"
# This needs to be configured dependant on your requirements, there is a tool"
# to help with this at https://rackerlabs.github.io/swift-ppc/, the defaults
# are for a very small poc cluster
RING_PART_POWER=9
RING_REPLICAS=3
MIN_PART_HOURS=2
init_swift_rings





init_gluster_volumes () {
  echo "######################################################################"
  echo "HarborOS: Gluster: Initialise volumes"
  echo "######################################################################"
  GLUSTER_POD=$(kubectl get pods --selector app=os-glusterfs-rc --no-headers --namespace=os-glusterfs | sed -n 1p | awk '{print $1}')
  kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster pool list
  source /etc/os-glusterfs/os-glusterfs.env
  GLUSTER_VOLUME_REPLICAS=${INITIAL_GLUSTER_HOSTS}
  OPENSTACK_COMPONENT=os-glusterfs
  CINDER_UID=165
  CINDER_GID=165

  while read -r GLUSTER_VOLUME_KEY; do
    GLUSTER_VOLUME=${GLUSTER_VOLUME_KEY##*/}
    echo "######################################################################"
    echo "HarborOS: Gluster: Initialise $GLUSTER_VOLUME"
    echo "######################################################################"
    GLUSTER_VOLUME_BRICKS=""
    while read -r GLUSTER_VOLUME_HOST_KEY; do
      GLUSTER_VOLUME_HOST=${GLUSTER_VOLUME_HOST_KEY##*/}
      echo "Gluster Volume: $GLUSTER_VOLUME Gluster Host: $GLUSTER_VOLUME_HOST"
      while read -r GLUSTER_VOLUME_BRICK_KEY; do
        GLUSTER_VOLUME_BRICK_DEV=${GLUSTER_VOLUME_BRICK_KEY##*/}
        GLUSTER_VOLUME_BRICK="$GLUSTER_VOLUME_HOST.$GLUSTER_DOMAIN:/bricks/$GLUSTER_VOLUME-$GLUSTER_VOLUME_BRICK_DEV/brick"
        GLUSTER_VOLUME_BRICKS="${GLUSTER_VOLUME_BRICKS} ${GLUSTER_VOLUME_BRICK}"
      done <<< "$(etcdctl ls /harboros/${OPENSTACK_COMPONENT}/bricks/${GLUSTER_VOLUME}/${GLUSTER_VOLUME_HOST})"
    done <<< "$(etcdctl ls /harboros/${OPENSTACK_COMPONENT}/bricks/${GLUSTER_VOLUME})"
    if [ "${GLUSTER_VOLUME}" == "os-cinder" ]; then
      kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume create ${GLUSTER_VOLUME} replica 2 transport tcp ${GLUSTER_VOLUME_BRICKS} force
    elif [ "${GLUSTER_VOLUME}" == "os-manila" ]; then
      kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume create ${GLUSTER_VOLUME} replica 2 transport tcp ${GLUSTER_VOLUME_BRICKS} force
    fi
    kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} auth.allow 10.*.*.*
    kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} nfs.disable off
    kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} nfs.addr-namelookup off
    kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} nfs.export-volumes on
    kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} nfs.rpc-auth-allow 10.*.*.*
    if [ "${GLUSTER_VOLUME}" == "os-cinder" ]; then
      kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} storage.owner-uid $CINDER_UID
      kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} storage.owner-gid $CINDER_GID
      kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume set ${GLUSTER_VOLUME} server.allow-insecure on
    fi
    #kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume stop ${GLUSTER_VOLUME}
    kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume start ${GLUSTER_VOLUME}
  done <<< "$(etcdctl ls /harboros/${OPENSTACK_COMPONENT}/bricks)"

  kubectl --namespace=os-glusterfs exec -it $GLUSTER_POD gluster volume status
}


GLUSTER_POD=$(kubectl get pods --selector app=os-glusterfs-rc --no-headers --namespace=os-glusterfs | sed -n 1p | awk '{print $1}')
kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster peer status
init_gluster_volumes

GLUSTER_POD=$(kubectl get pods --selector app=os-glusterfs-rc --no-headers --namespace=os-glusterfs | sed -n 1p | awk '{print $1}')
for GLUSTER_VOLUME in os-cinder os-manila; do
  kubectl --namespace=os-glusterfs exec $GLUSTER_POD gluster volume status $GLUSTER_VOLUME
done













action=status
echo "######################################################################"
echo "HarborOS: Starting: Database"
KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE os-database=true



/var/usrlocal/bin/os-database-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-database/kube/os-database_daemonset.yaml --namespace=os-database
/usr/local/bin/kubectl delete -f /etc/os-database/kube/os-database_secrets.yaml --namespace=os-database


/usr/local/bin/kubectl create -f /etc/os-database/kube/os-database_namespace.yaml
/usr/local/bin/kubectl create -f /etc/os-database/kube/os-database_secrets.yaml --namespace=os-database
/usr/local/bin/kubectl create -f /etc/os-database/kube/os-database_daemonset.yaml --namespace=os-database
/usr/local/bin/kubectl create -f /etc/os-database/kube/os-database_service.yaml --namespace=os-database
















echo "######################################################################"
echo "HarborOS: Starting: Messaging"



/var/usrlocal/bin/os-messaging-preflight.sh

/bin/kubectl delete -f /etc/os-messaging/kube/os-messaging_replicationcontroller.yaml --namespace=os-messaging
/bin/kubectl delete -f /etc/os-messaging/kube/os-messaging_secrets.yaml --namespace=os-messaging


/bin/kubectl create -f /etc/os-messaging/kube/os-messaging_namespace.yaml
/bin/kubectl create -f /etc/os-messaging/kube/os-messaging_secrets.yaml --namespace=os-messaging
/bin/kubectl create -f /etc/os-messaging/kube/os-messaging_replicationcontroller.yaml --namespace=os-messaging
/bin/kubectl create -f /etc/os-messaging/kube/os-messaging_service.yaml --namespace=os-messaging










(
OPENSTACK_COMPONENT=keystone
echo "######################################################################"
echo "HarborOS: Starting: ${OPENSTACK_COMPONENT}"
echo "######################################################################"
/var/usrlocal/bin/os-keystone-manager-flight.sh




MANAGER_POD=$(kubectl get pods --selector app=os-${OPENSTACK_COMPONENT}-manager-rc --no-headers --namespace=os-${OPENSTACK_COMPONENT} | sed -n 1p | awk '{print $1}')
kubectl logs $MANAGER_POD --namespace=os-${OPENSTACK_COMPONENT}



/var/usrlocal/bin/os-keystone-api-preflight.sh

/bin/kubectl delete -f /etc/os-keystone/kube/os-keystone-api_replicationcontroller.yaml --namespace=os-keystone
/bin/kubectl delete -f /etc/os-keystone/kube/os-keystone_secrets.yaml --namespace=os-keystone



/bin/kubectl create -f /etc/os-keystone/kube/os-keystone_secrets.yaml --namespace=os-keystone
/bin/kubectl create -f /etc/os-keystone/kube/os-keystone-api_replicationcontroller.yaml --namespace=os-keystone
/bin/kubectl create -f /etc/os-keystone/kube/os-keystone-api_service.yaml --namespace=os-keystone





)

(
OPENSTACK_COMPONENT=os-swift
echo "######################################################################"
echo "HarborOS: Starting: ${OPENSTACK_COMPONENT}"
echo "######################################################################"


/var/usrlocal/bin/os-swift-manager-flight.sh




MANAGER_POD=$(kubectl get pods --selector app=${OPENSTACK_COMPONENT}-manager-rc --no-headers --namespace=${OPENSTACK_COMPONENT} | sed -n 1p | awk '{print $1}')
kubectl logs $MANAGER_POD --namespace=${OPENSTACK_COMPONENT}




# for HOST in 10-140-38-147.port.direct 10-140-50-150.port.direct 10-140-63-249.port.direct; do
#   ssh $HOST rm -rf /var/lib/os-swift/sdc/*
# done
#
# for HOST in 10-140-38-147.port.direct 10-140-50-150.port.direct 10-140-63-249.port.direct; do
#   ssh $HOST ls -laR /var/lib/os-swift/sdc/
# done
# ls -laR /var/lib/os-swift/sdc/
# ls -laR /var/lib/os-swift/sdd/
/var/usrlocal/bin/os-swift-proxy-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-swift/kube/os-swift-proxy_service.yaml --namespace=os-swift
/usr/local/bin/kubectl delete -f /etc/os-swift/kube/os-swift-proxy_replicationcontroller.yaml --namespace=os-swift
/usr/local/bin/kubectl delete -f /etc/os-swift/kube/os-swift_secrets.yaml --namespace=os-swift



/usr/local/bin/kubectl create -f /etc/os-swift/kube/os-swift_namespace.yaml
/usr/local/bin/kubectl create -f /etc/os-swift/kube/os-swift_secrets.yaml --namespace=os-swift
/usr/local/bin/kubectl create -f /etc/os-swift/kube/os-swift-proxy_replicationcontroller.yaml --namespace=os-swift
/usr/local/bin/kubectl create -f /etc/os-swift/kube/os-swift-proxy_service.yaml --namespace=os-swift


/var/usrlocal/bin/${OPENSTACK_COMPONENT}-storage-preflight.sh

/usr/local/bin/kubectl delete -f /etc/${OPENSTACK_COMPONENT}/kube/${OPENSTACK_COMPONENT}-storage_daemonset.yaml --namespace=${OPENSTACK_COMPONENT}
/usr/local/bin/kubectl delete -f /etc/${OPENSTACK_COMPONENT}/kube/${OPENSTACK_COMPONENT}-storage_secrets.yaml --namespace=${OPENSTACK_COMPONENT}

/usr/local/bin/kubectl create -f /etc/${OPENSTACK_COMPONENT}/kube/${OPENSTACK_COMPONENT}_namespace.yaml
/usr/local/bin/kubectl create -f /etc/${OPENSTACK_COMPONENT}/kube/${OPENSTACK_COMPONENT}-storage_secrets.yaml --namespace=${OPENSTACK_COMPONENT}
/usr/local/bin/kubectl create -f /etc/${OPENSTACK_COMPONENT}/kube/${OPENSTACK_COMPONENT}-storage_daemonset.yaml --namespace=${OPENSTACK_COMPONENT}

kubectl get ds --namespace=${OPENSTACK_COMPONENT}
kubectl describe ds os-swift-storage --namespace=${OPENSTACK_COMPONENT}

)

(
  OPENSTACK_COMPONENT=cinder
  echo "######################################################################"
  echo "HarborOS: Starting: ${OPENSTACK_COMPONENT}"
  echo "######################################################################"
  KUBE_NODE=master.port.direct
  /usr/local/bin/kubectl label --overwrite node $KUBE_NODE cinder-storage=true
  #/var/usrlocal/bin/os-swift-manager-flight.sh

  MANAGER_POD=$(kubectl get pods --selector app=os-${OPENSTACK_COMPONENT}-manager-rc --no-headers --namespace=os-${OPENSTACK_COMPONENT} | sed -n 1p | awk '{print $1}')
  kubectl logs $MANAGER_POD --namespace=os-${OPENSTACK_COMPONENT}


  /var/usrlocal/bin/os-cinder-api-preflight.sh

  /bin/kubectl delete -f /etc/os-cinder/kube/os-cinder-api_service.yaml --namespace=os-cinder
  /bin/kubectl delete -f /etc/os-cinder/kube/os-cinder-api_replicationcontroller.yaml --namespace=os-cinder
  /bin/kubectl delete -f /etc/os-cinder/kube/os-cinder_secrets.yaml --namespace=os-cinder



  /bin/kubectl create -f /etc/os-cinder/kube/os-cinder_namespace.yaml
  /bin/kubectl create -f /etc/os-cinder/kube/os-cinder_secrets.yaml --namespace=os-cinder
  /bin/kubectl create -f /etc/os-cinder/kube/os-cinder-api_replicationcontroller.yaml --namespace=os-cinder
  /bin/kubectl create -f /etc/os-cinder/kube/os-cinder-api_service.yaml --namespace=os-cinder






  /var/usrlocal/bin/os-cinder-storage-preflight.sh

  /usr/local/bin/kubectl delete -f /etc/os-cinder/kube/os-cinder-storage_daemonset.yaml --namespace=os-cinder
  /usr/local/bin/kubectl delete -f /etc/os-cinder/kube/os-cinder-storage_secrets.yaml --namespace=os-cinder

  /usr/local/bin/kubectl create -f /etc/os-cinder/kube/os-cinder_namespace.yaml
  /usr/local/bin/kubectl create -f /etc/os-cinder/kube/os-cinder-storage_secrets.yaml --namespace=os-cinder
  /usr/local/bin/kubectl create -f /etc/os-cinder/kube/os-cinder-storage_daemonset.yaml --namespace=os-cinder
  sleep 120
  (
    kubectl --namespace=os-cinder exec -it $MANAGER_POD -- /bin/bash
    #source /openrc; cinder type-create GlusterFS; cinder type-key GlusterFS set volume_backend_name=GlusterfsDriver; cinder extra-specs-list
  )
)



./master-os-glance.sh
(
OPENSTACK_COMPONENT=glance
  echo "######################################################################"
  echo "HarborOS: Starting: ${OPENSTACK_COMPONENT}"
  echo "######################################################################"
  /var/usrlocal/bin/os-glance-manager-flight.sh
  MANAGER_POD=$(kubectl get pods --selector app=os-${OPENSTACK_COMPONENT}-manager-rc --no-headers --namespace=os-${OPENSTACK_COMPONENT} | sed -n 1p | awk '{print $1}')
  kubectl logs $MANAGER_POD --namespace=os-${OPENSTACK_COMPONENT}



  /var/usrlocal/bin/os-glance-api-preflight.sh

  #ExecStartPre=-/usr/local/bin/kubectl delete -f /etc/os-glance/kube/os-glance-api_service.yaml --namespace=os-glance
  /usr/local/bin/kubectl delete -f /etc/os-glance/kube/os-glance-api_replicationcontroller.yaml --namespace=os-glance
  /usr/local/bin/kubectl delete -f /etc/os-glance/kube/os-glance_secrets.yaml --namespace=os-glance




  /usr/local/bin/kubectl create -f /etc/os-glance/kube/os-glance_secrets.yaml --namespace=os-glance
  /usr/local/bin/kubectl create -f /etc/os-glance/kube/os-glance-api_replicationcontroller.yaml --namespace=os-glance
  /usr/local/bin/kubectl create -f /etc/os-glance/kube/os-glance-api_service.yaml --namespace=os-glance

  (
    kubectl --namespace=os-glance exec -it $MANAGER_POD -- glance-manage db_load_metadefs
  )
)




OPENSTACK_COMPONENT=neutron
echo "######################################################################"
echo "HarborOS: Starting: ${OPENSTACK_COMPONENT}"
echo "######################################################################"
(
KUBE_NODES=$(kubectl get nodes --no-headers| awk -F ' ' '{print $1}')
for KUBE_NODE in $KUBE_NODES
do
  /usr/local/bin/kubectl label --overwrite node $KUBE_NODE neutron-agent=true
done
KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE neutron-services=true
/var/usrlocal/bin/os-neutron-manager-flight.sh
MANAGER_POD=$(kubectl get pods --selector app=os-${OPENSTACK_COMPONENT}-manager-rc --no-headers --namespace=os-${OPENSTACK_COMPONENT} | sed -n 1p | awk '{print $1}')
kubectl logs $MANAGER_POD --namespace=os-${OPENSTACK_COMPONENT}




/var/usrlocal/bin/os-neutron-api-preflight.sh

#ExecStartPre=-/usr/local/bin/kubectl delete -f /etc/os-neutron/kube/os-neutron-api_service.yaml --namespace=os-neutron
/usr/local/bin/kubectl delete -f /etc/os-neutron/kube/os-neutron-api_replicationcontroller.yaml --namespace=os-neutron
/usr/local/bin/kubectl delete -f /etc/os-neutron/kube/os-neutron_secrets.yaml --namespace=os-neutron
/usr/local/bin/kubectl create -f /etc/os-neutron/kube/os-neutron_secrets.yaml --namespace=os-neutron
/usr/local/bin/kubectl create -f /etc/os-neutron/kube/os-neutron-api_replicationcontroller.yaml --namespace=os-neutron
/usr/local/bin/kubectl create -f /etc/os-neutron/kube/os-neutron-api_service.yaml --namespace=os-neutron

/var/usrlocal/bin/os-neutron-agent-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-neutron/kube/os-neutron-agent_daemonset.yaml --namespace=os-neutron
/usr/local/bin/kubectl delete -f /etc/os-neutron/kube/os-neutron-agent_secrets.yaml --namespace=os-neutron
/usr/local/bin/kubectl create -f /etc/os-neutron/kube/os-neutron-agent_secrets.yaml --namespace=os-neutron
/usr/local/bin/kubectl create -f /etc/os-neutron/kube/os-neutron-agent_daemonset.yaml --namespace=os-neutron

/var/usrlocal/bin/os-neutron-services-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-neutron/kube/os-neutron-services_daemonset.yaml --namespace=os-neutron
/usr/local/bin/kubectl delete -f /etc/os-neutron/kube/os-neutron-services_secrets.yaml --namespace=os-neutron
/usr/local/bin/kubectl create -f /etc/os-neutron/kube/os-neutron-services_secrets.yaml --namespace=os-neutron
/usr/local/bin/kubectl create -f /etc/os-neutron/kube/os-neutron-services_daemonset.yaml --namespace=os-neutron


systemctl ${action} os-${OPENSTACK_COMPONENT}-router
)

NEUTRON_POD=$(kubectl get pods --selector app=os-neutron-manager-rc --no-headers --namespace=os-neutron | sed -n 1p | awk '{print $1}')
kubectl --namespace=os-neutron exec -it $NEUTRON_POD -- /bootstrap.sh





(
OPENSTACK_COMPONENT=nova
echo "######################################################################"
echo "HarborOS: Starting: ${OPENSTACK_COMPONENT}"
echo "######################################################################"
KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE nova-novncproxy=true
KUBE_NODES=$(kubectl get nodes --no-headers| awk -F ' ' '{print $1}')
for KUBE_NODE in $KUBE_NODES
do
  /usr/local/bin/kubectl label --overwrite node $KUBE_NODE nova-compute='libvirt'
done
KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE nova-compute='none'

/var/usrlocal/bin/os-nova-manager-flight.sh
MANAGER_POD=$(kubectl get pods --selector app=os-${OPENSTACK_COMPONENT}-manager-rc --no-headers --namespace=os-${OPENSTACK_COMPONENT} | sed -n 1p | awk '{print $1}')
kubectl logs $MANAGER_POD --namespace=os-${OPENSTACK_COMPONENT}



/var/usrlocal/bin/os-nova-api-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-nova/kube/os-nova-api_replicationcontroller.yaml --namespace=os-nova
/usr/local/bin/kubectl delete -f /etc/os-nova/kube/os-nova_secrets.yaml --namespace=os-nova
/usr/local/bin/kubectl create -f /etc/os-nova/kube/os-nova_secrets.yaml --namespace=os-nova
/usr/local/bin/kubectl create -f /etc/os-nova/kube/os-nova-api_replicationcontroller.yaml --namespace=os-nova
/usr/local/bin/kubectl create -f /etc/os-nova/kube/os-nova-api_service.yaml --namespace=os-nova


/var/usrlocal/bin/os-nova-services-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-nova/kube/os-nova-services_replicationcontroller.yaml --namespace=os-nova
/usr/local/bin/kubectl delete -f /etc/os-nova/kube/os-nova-services_secrets.yaml --namespace=os-nova
/usr/local/bin/kubectl create -f /etc/os-nova/kube/os-nova-services_secrets.yaml --namespace=os-nova
/usr/local/bin/kubectl create -f /etc/os-nova/kube/os-nova-services_replicationcontroller.yaml --namespace=os-nova

/var/usrlocal/bin/os-nova-compute-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-nova/kube/os-nova-compute_daemonset.yaml --namespace=os-nova
/usr/local/bin/kubectl delete -f /etc/os-nova/kube/os-nova-compute_secrets.yaml --namespace=os-nova
/usr/local/bin/kubectl create -f /etc/os-nova/kube/os-nova-compute_secrets.yaml --namespace=os-nova
/usr/local/bin/kubectl create -f /etc/os-nova/kube/os-nova-compute_daemonset.yaml --namespace=os-nova

)



(



./master-os-horizon.sh
/var/usrlocal/bin/os-horizon-manager-flight.sh
/var/usrlocal/bin/os-horizon-api-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-horizon/kube/os-horizon-api_service.yaml --namespace=os-horizon
/usr/local/bin/kubectl delete -f /etc/os-horizon/kube/os-horizon-api_replicationcontroller.yaml --namespace=os-horizon
/usr/local/bin/kubectl delete -f /etc/os-horizon/kube/os-horizon_secrets.yaml --namespace=os-horizon


/usr/local/bin/kubectl create -f /etc/os-horizon/kube/os-horizon_secrets.yaml --namespace=os-horizon
/usr/local/bin/kubectl create -f /etc/os-horizon/kube/os-horizon-api_replicationcontroller.yaml --namespace=os-horizon
/usr/local/bin/kubectl create -f /etc/os-horizon/kube/os-horizon-api_service.yaml --namespace=os-horizon

)

action=restart
(




./master-os-heat.sh

/var/usrlocal/bin/os-heat-manager-flight.sh


/var/usrlocal/bin/os-heat-services-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-heat/kube/os-heat-services_replicationcontroller.yaml --namespace=os-heat
/usr/local/bin/kubectl delete -f /etc/os-heat/kube/os-heat-services_secrets.yaml --namespace=os-heat
/usr/local/bin/kubectl create -f /etc/os-heat/kube/os-heat-services_secrets.yaml --namespace=os-heat
/usr/local/bin/kubectl create -f /etc/os-heat/kube/os-heat-services_replicationcontroller.yaml --namespace=os-heat

/var/usrlocal/bin/os-heat-api-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-heat/kube/os-heat-api_service.yaml --namespace=os-heat
/usr/local/bin/kubectl delete -f /etc/os-heat/kube/os-heat-api_replicationcontroller.yaml --namespace=os-heat
/usr/local/bin/kubectl delete -f /etc/os-heat/kube/os-heat_secrets.yaml --namespace=os-heat
/usr/local/bin/kubectl create -f /etc/os-heat/kube/os-heat_secrets.yaml --namespace=os-heat
/usr/local/bin/kubectl create -f /etc/os-heat/kube/os-heat-api_replicationcontroller.yaml --namespace=os-heat
/usr/local/bin/kubectl create -f /etc/os-heat/kube/os-heat-api_service.yaml --namespace=os-heat



)


(

./master-os-murano.sh

/var/usrlocal/bin/os-murano-manager-flight.sh


/var/usrlocal/bin/os-murano-services-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-murano/kube/os-murano-services_replicationcontroller.yaml --namespace=os-murano
/usr/local/bin/kubectl delete -f /etc/os-murano/kube/os-murano-services_secrets.yaml --namespace=os-murano
/usr/local/bin/kubectl create -f /etc/os-murano/kube/os-murano-services_secrets.yaml --namespace=os-murano
/usr/local/bin/kubectl create -f /etc/os-murano/kube/os-murano-services_replicationcontroller.yaml --namespace=os-murano

/var/usrlocal/bin/os-murano-api-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-murano/kube/os-murano-api_service.yaml --namespace=os-murano
/usr/local/bin/kubectl delete -f /etc/os-murano/kube/os-murano-api_replicationcontroller.yaml --namespace=os-murano
/usr/local/bin/kubectl delete -f /etc/os-murano/kube/os-murano_secrets.yaml --namespace=os-murano
/usr/local/bin/kubectl create -f /etc/os-murano/kube/os-murano_secrets.yaml --namespace=os-murano
/usr/local/bin/kubectl create -f /etc/os-murano/kube/os-murano-api_replicationcontroller.yaml --namespace=os-murano
/usr/local/bin/kubectl create -f /etc/os-murano/kube/os-murano-api_service.yaml --namespace=os-murano
sleep 120
MURANO_POD=$(kubectl get pods --selector app=os-murano-manager-rc --no-headers --namespace=os-murano | sed -n 1p | awk '{print $1}')
kubectl --namespace=os-murano exec -it $MURANO_POD -- murano-manage --config-file ./etc/murano/murano.conf import-package /murano/meta/io.murano


)

(
/var/usrlocal/bin/os-barbican-manager-flight.sh

/var/usrlocal/bin/os-barbican-api-preflight.sh
/usr/local/bin/kubectl delete -f /etc/os-barbican/kube/os-barbican-api_replicationcontroller.yaml --namespace=os-barbican
/usr/local/bin/kubectl delete -f /etc/os-barbican/kube/os-barbican_secrets.yaml --namespace=os-barbican



/usr/local/bin/kubectl create -f /etc/os-barbican/kube/os-barbican_secrets.yaml --namespace=os-barbican
/usr/local/bin/kubectl create -f /etc/os-barbican/kube/os-barbican-api_replicationcontroller.yaml --namespace=os-barbican
/usr/local/bin/kubectl create -f /etc/os-barbican/kube/os-barbican-api_service.yaml --namespace=os-barbican
)














(
/var/usrlocal/bin/os-magnum-manager-flight.sh

/var/usrlocal/bin/os-magnum-api-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-magnum/kube/os-magnum-api_service.yaml --namespace=os-magnum
/usr/local/bin/kubectl delete -f /etc/os-magnum/kube/os-magnum-api_replicationcontroller.yaml --namespace=os-magnum
/usr/local/bin/kubectl delete -f /etc/os-magnum/kube/os-magnum_secrets.yaml --namespace=os-magnum


/usr/local/bin/kubectl create -f /etc/os-magnum/kube/os-magnum_secrets.yaml --namespace=os-magnum
/usr/local/bin/kubectl create -f /etc/os-magnum/kube/os-magnum-api_replicationcontroller.yaml --namespace=os-magnum
/usr/local/bin/kubectl create -f /etc/os-magnum/kube/os-magnum-api_service.yaml --namespace=os-magnum
)




echo "######################################################################"
echo "HarborOS: Starting: MongoDB Database"
KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE os-mongodb=true



/var/usrlocal/bin/os-mongodb-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-mongodb/kube/os-mongodb_daemonset.yaml --namespace=os-mongodb
/usr/local/bin/kubectl delete -f /etc/os-mongodb/kube/os-mongodb_secrets.yaml --namespace=os-mongodb


/usr/local/bin/kubectl create -f /etc/os-mongodb/kube/os-mongodb_namespace.yaml
/usr/local/bin/kubectl create -f /etc/os-mongodb/kube/os-mongodb_secrets.yaml --namespace=os-mongodb
/usr/local/bin/kubectl create -f /etc/os-mongodb/kube/os-mongodb_daemonset.yaml --namespace=os-mongodb
/usr/local/bin/kubectl create -f /etc/os-mongodb/kube/os-mongodb_service.yaml --namespace=os-mongodb



(
./master-os-ceilometer.sh./master-os-ceilometer.sh
/var/usrlocal/bin/os-ceilometer-manager-flight.sh

/var/usrlocal/bin/os-ceilometer-api-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-ceilometer/kube/os-ceilometer-api_service.yaml --namespace=os-ceilometer
/usr/local/bin/kubectl delete -f /etc/os-ceilometer/kube/os-ceilometer-api_replicationcontroller.yaml --namespace=os-ceilometer
/usr/local/bin/kubectl delete -f /etc/os-ceilometer/kube/os-ceilometer_secrets.yaml --namespace=os-ceilometer


/usr/local/bin/kubectl create -f /etc/os-ceilometer/kube/os-ceilometer_secrets.yaml --namespace=os-ceilometer
/usr/local/bin/kubectl create -f /etc/os-ceilometer/kube/os-ceilometer-api_replicationcontroller.yaml --namespace=os-ceilometer
/usr/local/bin/kubectl create -f /etc/os-ceilometer/kube/os-ceilometer-api_service.yaml --namespace=os-ceilometer


/var/usrlocal/bin/os-ceilometer-polling-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-ceilometer/kube/os-ceilometer-services_daemonset.yaml --namespace=os-ceilometer
/usr/local/bin/kubectl delete -f /etc/os-ceilometer/kube/os-ceilometer-services_secrets.yaml --namespace=os-ceilometer

/usr/local/bin/kubectl create -f /etc/os-ceilometer/kube/os-ceilometer-services_secrets.yaml --namespace=os-ceilometer
/usr/local/bin/kubectl create -f /etc/os-ceilometer/kube/os-ceilometer-services_daemonset.yaml --namespace=os-ceilometer
)









./master-os-accounts.sh


/var/usrlocal/bin/os-accounts-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-accounts/kube/os-accounts_replicationcontroller.yaml --namespace=os-accounts
/usr/local/bin/kubectl delete -f /etc/os-accounts/kube/os-accounts_secrets.yaml --namespace=os-accounts


/usr/local/bin/kubectl create -f /etc/os-accounts/kube/os-accounts_namespace.yaml
/usr/local/bin/kubectl create -f /etc/os-accounts/kube/os-accounts_secrets.yaml --namespace=os-accounts
/usr/local/bin/kubectl create -f /etc/os-accounts/kube/os-accounts_replicationcontroller.yaml --namespace=os-accounts
/usr/local/bin/kubectl create -f /etc/os-accounts/kube/os-accounts_service.yaml --namespace=os-accounts



./master-os-proxy.sh



/var/usrlocal/bin/os-proxy-preflight.sh

/usr/local/bin/kubectl delete -f /etc/os-proxy/kube/os-proxy_replicationcontroller.yaml --namespace=os-proxy
/usr/local/bin/kubectl delete -f /etc/os-proxy/kube/os-proxy_secrets.yaml --namespace=os-proxy


/usr/local/bin/kubectl create -f /etc/os-proxy/kube/os-proxy_namespace.yaml
/usr/local/bin/kubectl create -f /etc/os-proxy/kube/os-proxy_secrets.yaml --namespace=os-proxy
/usr/local/bin/kubectl create -f /etc/os-proxy/kube/os-proxy_replicationcontroller.yaml --namespace=os-proxy
/usr/local/bin/kubectl create -f /etc/os-proxy/kube/os-proxy_service.yaml --namespace=os-proxy
