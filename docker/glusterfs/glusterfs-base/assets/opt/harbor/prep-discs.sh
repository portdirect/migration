#!/bin/sh
set -e
PATH=/usr/local/bin:${PATH}
: ${HARBOR_GLUSTER_VG:=harbor-gluster}


: ${HARBOR_GLUSTER_DATA_POOL:=gluster-pool}
: ${HARBOR_GLUSTER_DATA_POOL_SIZE:='90%FREE'}
: ${HARBOR_GLUSTER_DATA_METADATA_SIZE:=1G}

HOSTNAME="$(hostname -s)"
HARBOROS_ETCD_ROOT="/harboros"
GLUSTER_ROLE="glusterfs"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Prepping the devices"
################################################################################
prep_gluster_devs () {
  for DISC_TYPE in ssd hdd; do
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/${HOSTNAME} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          DEVICE=$(echo ${ETCD_KEY%/*} | sed 's#.*/##')
          if [ "${ROLE}" == "${GLUSTER_ROLE}" ]; then
            echo "Identified ${DEVICE} as a gluster volume"
            # if the device is not ininitialzed as a lvm pv do that now
            pvdisplay /dev/${DEVICE}1 || (
              parted  --script /dev/${DEVICE} mklabel GPT
              parted  --script /dev/${DEVICE} mkpart primary 1MiB 100%
              parted  --script /dev/${DEVICE} set 1 lvm on
              pvcreate /dev/${DEVICE}1
              pvdisplay /dev/${DEVICE}1
            )
            if vgscan | grep -q "${HARBOR_GLUSTER_VG}-${DEVICE}"; then
              vgdisplay ${HARBOR_GLUSTER_VG}-${DEVICE}
            else
              vgcreate ${HARBOR_GLUSTER_VG}-${DEVICE} /dev/${DEVICE}1
              vgdisplay ${HARBOR_GLUSTER_VG}-${DEVICE}
            fi

            if lvscan | grep "/dev/${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE}"; then
                echo "${HARBOR_GLUSTER_VG}-${DEVICE} is prepped"
            else
              echo y | lvcreate -n ${HARBOR_GLUSTER_VG}-${DEVICE}-metadata -L ${HARBOR_GLUSTER_DATA_METADATA_SIZE} ${HARBOR_GLUSTER_VG}-${DEVICE}
              lvcreate -n ${HARBOR_GLUSTER_VG}-${DEVICE} -l ${HARBOR_GLUSTER_DATA_POOL_SIZE} ${HARBOR_GLUSTER_VG}-${DEVICE}
              lvconvert --yes --type thin-pool --poolmetadata ${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE}-metadata ${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE}
            fi
          fi
        done
  done
}
prep_gluster_devs


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Prepping the volume for /var/lib/glusterd"
################################################################################
prep_var_lib_glusterd () {
  for DISC_TYPE in ssd hdd; do
    etcdctl ls --sort -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/${HOSTNAME} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          DEVICE=$(echo ${ETCD_KEY%/*} | sed 's#.*/##')
          if [ "${ROLE}" == "${GLUSTER_ROLE}" ]; then
            ETCD_KEY=$(etcdctl ls --sort -recursive ${HARBOROS_ETCD_ROOT}/volumes/$(hostname -s) | head -1)
            GLUSTER_VOLUME_SIZE=$(etcdctl get ${ETCD_KEY})
            GLUSTER_VOLUME_NAME=$(basename ${ETCD_KEY%/} )
            echo $DEVICE var-lib-glusterd 20G
            if lvscan | grep "/dev/${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE}"
              then
              ( lvdisplay ${HARBOR_GLUSTER_VG}-${DEVICE}/var-lib-glusterd ) || \
                (
                  lvcreate -V20G -T ${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE} -n var-lib-glusterd && \
                  mkfs.xfs -i size=512 /dev/${HARBOR_GLUSTER_VG}-${DEVICE}/var-lib-glusterd
                  lvdisplay ${HARBOR_GLUSTER_VG}-${DEVICE}/var-lib-glusterd
                )
            fi
            umount /var/lib/glusterd || true
            mkdir -p /var/lib/glusterd
            mount /dev/${HARBOR_GLUSTER_VG}-${DEVICE}/var-lib-glusterd /var/lib/glusterd

          fi
        done
  done
}
prep_var_lib_glusterd


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Prepping the volumes and bricks"
################################################################################
prep_gluster_vol_bricks () {
  for DISC_TYPE in ssd hdd; do
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/${HOSTNAME} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          DEVICE=$(echo ${ETCD_KEY%/*} | sed 's#.*/##')
          if [ "${ROLE}" == "${GLUSTER_ROLE}" ]; then
            etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/volumes/$(hostname -s) | \
                while read ETCD_KEY; do
                  GLUSTER_VOLUME_SIZE=$(etcdctl get ${ETCD_KEY})
                  GLUSTER_VOLUME_NAME=$(basename ${ETCD_KEY%/} )
                  echo $DEVICE $GLUSTER_VOLUME_NAME $GLUSTER_VOLUME_SIZE
                  if lvscan | grep "/dev/${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE}"
                    then
                    ( lvdisplay ${HARBOR_GLUSTER_VG}-${DEVICE}/${GLUSTER_VOLUME_NAME} ) || \
                      (
                        lvcreate -V${GLUSTER_VOLUME_SIZE} -T ${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE} -n ${GLUSTER_VOLUME_NAME} && \
                        mkfs.xfs -i size=512 /dev/${HARBOR_GLUSTER_VG}-${DEVICE}/${GLUSTER_VOLUME_NAME}
                        lvdisplay ${HARBOR_GLUSTER_VG}-${DEVICE}/${GLUSTER_VOLUME_NAME}
                      )
                  fi
                done
          fi
        done
  done
}
prep_gluster_vol_bricks


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Mounting Bricks"
################################################################################
mount_gluster_vol_bricks () {
  for DISC_TYPE in ssd hdd; do
    etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/discs/${DISC_TYPE}/${HOSTNAME} | grep role | \
        while read ETCD_KEY; do
          ROLE=$(etcdctl get ${ETCD_KEY})
          DEVICE=$(echo ${ETCD_KEY%/*} | sed 's#.*/##')
          if [ "${ROLE}" == "${GLUSTER_ROLE}" ]; then
            etcdctl ls -recursive ${HARBOROS_ETCD_ROOT}/volumes/$(hostname -s) | \
                while read ETCD_KEY; do
                  GLUSTER_VOLUME_SIZE=$(etcdctl get ${ETCD_KEY})
                  GLUSTER_VOLUME_NAME=$(basename ${ETCD_KEY%/} )
                  echo $DEVICE $GLUSTER_VOLUME_NAME $GLUSTER_VOLUME_SIZE
                  if lvscan | grep "/dev/${HARBOR_GLUSTER_VG}-${DEVICE}/${HARBOR_GLUSTER_VG}-${DEVICE}"
                    then
                    if mount | grep "/export/${GLUSTER_VOLUME_NAME}/${DEVICE}"; then
                      echo "Filesystem already mounted at /export/${GLUSTER_VOLUME_NAME}/${DEVICE} , not attempting to mount"
                    else
                      echo "Mounting /dev/${HARBOR_GLUSTER_VG}-${DEVICE}/${GLUSTER_VOLUME_NAME} @ /export/${GLUSTER_VOLUME_NAME}/${DEVICE}"
                      mkdir -p /export/${GLUSTER_VOLUME_NAME}/${DEVICE}
                      mount /dev/${HARBOR_GLUSTER_VG}-${DEVICE}/${GLUSTER_VOLUME_NAME} /export/${GLUSTER_VOLUME_NAME}/${DEVICE}
                    fi
                    mkdir -p /export/${GLUSTER_VOLUME_NAME}/${DEVICE}/brick
                  fi
                done
          fi
        done
  done
}
mount_gluster_vol_bricks


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Displaying mounted Filesystems"
################################################################################
mount
