

GLUSTER_DEV=sdb

GLUSTER_VG=gluster
GUSTER_HOSTNAME=$(hostname -s)

parted -s -- /dev/${GLUSTER_DEV} mktable gpt
parted -s -- /dev/${GLUSTER_DEV} mkpart primary 2048s 100%
parted -s -- /dev/${GLUSTER_DEV} set 1 lvm on

pvcreate /dev/${GLUSTER_DEV}
vgcreate ${GLUSTER_VG} /dev/${GLUSTER_DEV}1
echo y | lvcreate --wipesignatures=y -l 100%VG -n "${GUSTER_HOSTNAME}-${GLUSTER_DEV}" ${GLUSTER_VG}
mkfs.xfs -i size=512 /dev/${GLUSTER_VG}/${GUSTER_HOSTNAME}-${GLUSTER_DEV}
