#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=glusterfs
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
# Cinder Volume
: ${GLUSTER_FS_SHARE:="glusterfs.${OS_DOMAIN}:/os-cinder"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg GLUSTER_FS_SHARE




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: GlusterFS"
################################################################################
crudini --set $cfg DEFAULT default_volume_type "GlusterFS"
crudini --set $cfg DEFAULT enabled_backends "GlusterfsDriver"
crudini --set $cfg GlusterfsDriver volume_backend_name "GlusterfsDriver"
crudini --set $cfg GlusterfsDriver volume_driver "cinder.volume.drivers.glusterfs.GlusterfsDriver"
crudini --set $cfg DEFAULT secure_delete "false"
#crudini --set $cfg DEFAULT glusterfs_backup_mount_point = /mnt/os-cinder/backup
#crudini --set $cfg DEFAULT glusterfs_backup_share = None
crudini --set $cfg GlusterfsDriver glusterfs_mount_point_base "/mnt/os-cinder/mnt"
crudini --set $cfg GlusterfsDriver glusterfs_shares_config "/etc/cinder/glusterfs_shares"
crudini --set $cfg GlusterfsDriver nas_volume_prov_type "thin"

mkdir -p /mnt/os-cinder/mnt

cat > /etc/cinder/glusterfs_shares <<EOF
${GLUSTER_FS_SHARE}
EOF
chown root:cinder /etc/cinder/glusterfs_shares
chmod 0640 /etc/cinder/glusterfs_shares
