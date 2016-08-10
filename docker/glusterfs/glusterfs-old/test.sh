



HARBOR_GLUSTER_VG=harbor-gluster
HARBOR_GLUSTER_VG_DEVS=sdb
HARBOR_GLUSTER_LIB_VOL=var-lib-glusterd
HARBOR_GLUSTER_LIB_DIR=/var/lib/glusterd
HARBOR_GLUSTER_LIB_SIZE=4G


HARBOR_GLUSTER_DATA_POOL=gluster-pool
HARBOR_GLUSTER_DATA_POOL_SIZE=90%FREE
HARBOR_GLUSTER_DATA_METADATA_SIZE=1G




GLUSTER_VOLUME_NAME=os-ipa
GLUSTER_VOLUME_SIZE=10G
lvcreate -V${GLUSTER_VOLUME_SIZE} -T ${HARBOR_GLUSTER_VG}/${HARBOR_GLUSTER_DATA_POOL}-data -n ${GLUSTER_VOLUME_NAME}
mkfs.xfs -i size=512 /dev/${HARBOR_GLUSTER_VG}/${GLUSTER_VOLUME_NAME}

GLUSTER_VOLUME_NAME=os-database
GLUSTER_VOLUME_SIZE=10G
lvcreate -V${GLUSTER_VOLUME_SIZE} -T ${HARBOR_GLUSTER_VG}/${HARBOR_GLUSTER_DATA_POOL}-data -n ${GLUSTER_VOLUME_NAME}
mkfs.xfs -i size=512 /dev/${HARBOR_GLUSTER_VG}/${GLUSTER_VOLUME_NAME}

GLUSTER_VOLUME_NAME=os-glance
GLUSTER_VOLUME_SIZE=20G
lvcreate -V${GLUSTER_VOLUME_SIZE} -T ${HARBOR_GLUSTER_VG}/${HARBOR_GLUSTER_DATA_POOL}-data -n ${GLUSTER_VOLUME_NAME}
mkfs.xfs -i size=512 /dev/${HARBOR_GLUSTER_VG}/${GLUSTER_VOLUME_NAME}

GLUSTER_VOLUME_NAME=os-cinder
GLUSTER_VOLUME_SIZE=80G
lvcreate -V${GLUSTER_VOLUME_SIZE} -T ${HARBOR_GLUSTER_VG}/${HARBOR_GLUSTER_DATA_POOL}-data -n ${GLUSTER_VOLUME_NAME}
mkfs.xfs -i size=512 /dev/${HARBOR_GLUSTER_VG}/${GLUSTER_VOLUME_NAME}


gluster pool list

OPENSTACK_COMPONENT=os-glusterfs

if [ ! -f /etc/os-container.env ]; then
  ################################################################################
  echo "${OS_DISTRO}: Generating local environment file from secrets_dir"
  ################################################################################
  SECRETS_DIR=/etc/os-config
  find $SECRETS_DIR -type f -printf "\n#%p\n" -exec bash -c "cat {} | sed  's|\\\n$||g'" \; > /etc/os-container.env
fi

################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


GLUSTER_VOLUME_NAME=os-database
GLUSTER_VOLUME_REPLICAS=2
################################################################################
echo "${OS_DISTRO}:Building peer group"
################################################################################
GLUSTER_VOLUME_BRICKS=""
while read -r REGISTERED_GLUSTER_HOST_KEY; do
  if [ "$REGISTERED_GLUSTER_HOST_KEY" != "${SKYDNS_BASE_KEY}/${OPENSTACK_COMPONENT}/${GLUSTER_HOST}" ]; then
    REGISTERED_GLUSTER_HOST=$(echo $REGISTERED_GLUSTER_HOST_KEY | awk -F"/" '{for (i=NF;i;i--) printf "%s.",$i; print ""}' | sed "s/.${SKYDNS_ETCD_ROOT}..\$//")
    REGISTERED_GLUSTER_HOST_BRICK_PATH=/bricks/${GLUSTER_VOLUME_NAME}/brick
    GLUSTER_VOLUME_BRICKS="${GLUSTER_VOLUME_BRICKS} ${REGISTERED_GLUSTER_HOST}:${REGISTERED_GLUSTER_HOST_BRICK_PATH}"
  fi
done <<< "$(etcdctl ls --recursive ${SKYDNS_BASE_KEY}/${OPENSTACK_COMPONENT})"
echo $GLUSTER_VOLUME_BRICKS



gluster volume create ${GLUSTER_VOLUME_NAME} replica ${GLUSTER_VOLUME_REPLICAS} transport tcp ${GLUSTER_VOLUME_BRICKS}
gluster volume set ${GLUSTER_VOLUME_NAME} auth.allow 10.*.*.*
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.disable off
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.addr-namelookup off
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.export-volumes on
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.rpc-auth-allow 10.*.*.*
gluster volume start ${GLUSTER_VOLUME_NAME}



GLUSTER_VOLUME_NAME=os-glance
GLUSTER_VOLUME_REPLICAS=2
################################################################################
echo "${OS_DISTRO}:Building peer group"
################################################################################
GLUSTER_VOLUME_BRICKS=""
while read -r REGISTERED_GLUSTER_HOST_KEY; do
  if [ "$REGISTERED_GLUSTER_HOST_KEY" != "${SKYDNS_BASE_KEY}/${OPENSTACK_COMPONENT}/${GLUSTER_HOST}" ]; then
    REGISTERED_GLUSTER_HOST=$(echo $REGISTERED_GLUSTER_HOST_KEY | awk -F"/" '{for (i=NF;i;i--) printf "%s.",$i; print ""}' | sed "s/.${SKYDNS_ETCD_ROOT}..\$//")
    REGISTERED_GLUSTER_HOST_BRICK_PATH=/bricks/${GLUSTER_VOLUME_NAME}/brick
    GLUSTER_VOLUME_BRICKS="${GLUSTER_VOLUME_BRICKS} ${REGISTERED_GLUSTER_HOST}:${REGISTERED_GLUSTER_HOST_BRICK_PATH}"
  fi
done <<< "$(etcdctl ls --recursive ${SKYDNS_BASE_KEY}/${OPENSTACK_COMPONENT})"
echo $GLUSTER_VOLUME_BRICKS



gluster volume create ${GLUSTER_VOLUME_NAME} replica ${GLUSTER_VOLUME_REPLICAS} transport tcp ${GLUSTER_VOLUME_BRICKS}
gluster volume set ${GLUSTER_VOLUME_NAME} auth.allow 10.*.*.*
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.disable off
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.addr-namelookup off
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.export-volumes on
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.rpc-auth-allow 10.*.*.*
gluster volume start ${GLUSTER_VOLUME_NAME}



GLUSTER_VOLUME_NAME=os-cinder
GLUSTER_VOLUME_REPLICAS=2
################################################################################
echo "${OS_DISTRO}:Building peer group"
################################################################################
GLUSTER_VOLUME_BRICKS=""
while read -r REGISTERED_GLUSTER_HOST_KEY; do
  if [ "$REGISTERED_GLUSTER_HOST_KEY" != "${SKYDNS_BASE_KEY}/${OPENSTACK_COMPONENT}/${GLUSTER_HOST}" ]; then
    REGISTERED_GLUSTER_HOST=$(echo $REGISTERED_GLUSTER_HOST_KEY | awk -F"/" '{for (i=NF;i;i--) printf "%s.",$i; print ""}' | sed "s/.${SKYDNS_ETCD_ROOT}..\$//")
    REGISTERED_GLUSTER_HOST_BRICK_PATH=/bricks/${GLUSTER_VOLUME_NAME}/brick
    GLUSTER_VOLUME_BRICKS="${GLUSTER_VOLUME_BRICKS} ${REGISTERED_GLUSTER_HOST}:${REGISTERED_GLUSTER_HOST_BRICK_PATH}"
  fi
done <<< "$(etcdctl ls --recursive ${SKYDNS_BASE_KEY}/${OPENSTACK_COMPONENT})"
echo $GLUSTER_VOLUME_BRICKS


CINDER_UID=165
CINDER_GID=165
gluster volume create ${GLUSTER_VOLUME_NAME} replica ${GLUSTER_VOLUME_REPLICAS} transport tcp ${GLUSTER_VOLUME_BRICKS}
gluster volume set ${GLUSTER_VOLUME_NAME} auth.allow 10.*.*.*
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.disable off
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.addr-namelookup off
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.export-volumes on
gluster volume set ${GLUSTER_VOLUME_NAME} nfs.rpc-auth-allow 10.*.*.*
gluster volume set ${GLUSTER_VOLUME_NAME} storage.owner-uid $CINDER_UID
gluster volume set ${GLUSTER_VOLUME_NAME} storage.owner-gid $CINDER_GID
gluster volume set ${GLUSTER_VOLUME_NAME} server.allow-insecure on

gluster volume start ${GLUSTER_VOLUME_NAME}




cinder type-create GlusterFS
cinder type-key GlusterFS set volume_backend_name=GlusterfsDriver
cinder extra-specs-list



cat > os-gluster-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: glusterfs
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: "/mnt/glusterfs"
      name: glusterfsvol
  volumes:
  - name: glusterfsvol
    glusterfs:
      endpoints: os-glusterfs
      path: os-swift
      readOnly: false
EOF
cat os-gluster-pod.yaml
kubectl delete -f os-gluster-pod.yaml --namespace=os-glusterfs
kubectl create -f os-gluster-pod.yaml --namespace=os-glusterfs


cat > /etc/os-database/kube/os-database_volume_definition.yaml <<EOF
kind: PersistentVolume
apiVersion: v1
metadata:
  name: os-database
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  glusterfs:
    endpoints: os-glusterfs
    path: os-database
    readOnly: false
EOF
cat > /etc/os-database/kube/os-database_volume_claim.yaml <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: os-database
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    name: os-database
    requests:
      storage: 10Gi
EOF

cat > /etc/os-database/kube/os-database_replicationcontroller.yaml <<EOF
apiVersion: v1
kind: ReplicationController
metadata:
 name: os-database
spec:
 replicas: 1
 template:
   metadata:
     labels:
       app: os-database-rc
     name: os-database
   spec:
     containers:
       - name: os-database
         image: registry.harboros.net:3040/harboros/mariadb-app:latest
         ports:
           - containerPort: 3306
         env:
           - name: OS_HOSTNAME
             value: os-database.port.direct
         volumeMounts:
           - name: os-database-config
             mountPath: "/etc/os-config"
             readOnly: true
           - name: os-database-storage
             mountPath: "/var/lib/mysql"
         resources:
           limits:
             cpu: "0.5"
         securityContext:
           privileged: true
           capabilities:
             drop:
               - ALL
     volumes:
       - name: os-database-config
         secret:
           secretName: os-database
       - name: os-database-storage
         persistentVolumeClaim:
           claimName: os-database
EOF
/bin/kubectl create -f /etc/os-database/kube/os-database_namespace.yaml
/bin/kubectl delete -f /etc/os-database/kube/os-database_volume_definition.yaml --namespace=os-database
/bin/kubectl delete -f /etc/os-database/kube/os-database_volume_claim.yaml --namespace=os-database
/bin/kubectl delete -f /etc/os-database/kube/os-database_replicationcontroller.yaml --namespace=os-database
/bin/kubectl create -f /etc/os-database/kube/os-database_secrets.yaml --namespace=os-database
/bin/kubectl create -f /etc/os-database/kube/os-database_volume_definition.yaml --namespace=os-glusterfs
/bin/kubectl create -f /etc/os-database/kube/os-database_volume_claim.yaml --namespace=os-database
/bin/kubectl create -f /etc/os-database/kube/os-database_replicationcontroller.yaml --namespace=os-database
#ping ${OPENSTACK_COMPONENT}.${OS_KUBE_NAMESPACE}.svc.${OS_KUBE_DOMAIN}
