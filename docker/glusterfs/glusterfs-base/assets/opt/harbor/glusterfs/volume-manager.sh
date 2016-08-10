#!/bin/bash
set -e
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/glusterfs/common-env.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars GLUSTERFS_DEVICE ETCDCTL_ENDPOINT


HOSTNAME="$(hostname -s)"
#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Performing Election"
################################################################################


HARBOROS_ETCD_ROOT=/harboros
CINDER_UID=165
CINDER_GID=165

CURRENT_LEADER="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/current-leader)"
if [ "${HOSTNAME}" != "${CURRENT_LEADER}" ]; then
  echo "We are not the leader, not performing management tasks"
  sleep 360
  exit 0
else
  echo "We are the leader, performing management tasks"
  etcdctl ls ${HARBOROS_ETCD_ROOT}/gluster-volumes | \
      while read ETCD_KEY; do
        GLUSTER_VOLUME_NAME=$(basename ${ETCD_KEY%/} )
        GLUSTER_VOLUME_CREATE_OPTS=$( etcdctl get ${HARBOROS_ETCD_ROOT}/gluster-volumes/${GLUSTER_VOLUME_NAME}/options/creation | tr '=' ' ' )
        GLUSTER_VOLUME_OPTS=$( etcdctl get ${HARBOROS_ETCD_ROOT}/gluster-volumes/${GLUSTER_VOLUME_NAME}/options/runtime )
        GLUSTER_VOLUME_BRICKS=$(etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/volumes | sed -ne "/${GLUSTER_VOLUME_NAME}$/p" | sed "s,^${HARBOROS_ETCD_ROOT}/volumes/,," | sed "s,/${GLUSTER_VOLUME_NAME}\$,," | \
                while read GLUSTER_VOLUME_HOST; do
                    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/volumes/${GLUSTER_VOLUME_HOST} | grep ${GLUSTER_VOLUME_NAME} | \
                        while read ETCD_KEY; do
                          GLUSTER_VOLUME_HOST="$(echo $ETCD_KEY | sed "s,^${HARBOROS_ETCD_ROOT}/volumes/,," | sed "s,/${GLUSTER_VOLUME_NAME}\$,,")"
                          GLUSTER_VOLUME_HOST_IP=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${GLUSTER_VOLUME_HOST}/ip)
                          GLUSTER_VOLUME_HOSTNAME=${GLUSTER_VOLUME_HOST}.storage.node.local
                          for DISC_TYPE in ssd hdd; do
                            etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/${GLUSTER_VOLUME_HOST} | grep role | \
                              while read ETCD_KEY; do
                                ROLE=$(etcdctl get ${ETCD_KEY})
                                DEVICE=$(echo ${ETCD_KEY%/*} | sed 's#.*/##')
                                if [ "${ROLE}" == "${GLUSTER_ROLE}" ]; then
                                  printf "${GLUSTER_VOLUME_HOSTNAME}:/export/${GLUSTER_VOLUME_NAME}/${DEVICE}/brick "
                                fi
                              done
                          done
                        done
                done)
              echo ${GLUSTER_VOLUME_BRICKS}
              if [ "${GLUSTER_VOLUME}" == "os-cinder" ]; then
                GLUSTER_VOLUME_OPTS=""
              elif [ "${GLUSTER_VOLUME}" == "os-mongodb" ]; then
                GLUSTER_VOLUME_OPTS=""
              else
                GLUSTER_VOLUME_OPTS="replica 2"
              fi
              (gluster volume list | grep -q ${GLUSTER_VOLUME_NAME}) || gluster volume create ${GLUSTER_VOLUME_NAME} ${GLUSTER_VOLUME_OPTS} transport tcp ${GLUSTER_VOLUME_BRICKS} force

              if [ "${GLUSTER_VOLUME}" == "os-cinder" ]; then
                gluster volume set ${GLUSTER_VOLUME} storage.owner-uid $CINDER_UID
                gluster volume set ${GLUSTER_VOLUME} storage.owner-gid $CINDER_GID
                gluster volume set ${GLUSTER_VOLUME} server.allow-insecure on
              fi

              gluster volume set ${GLUSTER_VOLUME_NAME} auth.allow 10.*.*.*
              gluster volume set ${GLUSTER_VOLUME_NAME} nfs.disable off
              gluster volume set ${GLUSTER_VOLUME_NAME} nfs.addr-namelookup off
              gluster volume set ${GLUSTER_VOLUME_NAME} nfs.export-volumes on
              gluster volume set ${GLUSTER_VOLUME_NAME} nfs.rpc-auth-allow 10.*.*.*
              gluster volume status ${GLUSTER_VOLUME_NAME} || ( gluster volume start ${GLUSTER_VOLUME_NAME} && gluster volume status ${GLUSTER_VOLUME_NAME} )

          done
fi
