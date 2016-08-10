#!/bin/sh


yum install -y docker etcd bridge-utils crudini bind-utils ipa-client





cat > /etc/selinux/config <<EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
# enforcing - SELinux security policy is enforced.
# permissive - SELinux prints warnings instead of enforcing.
# disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these three values:
# targeted - Targeted processes are protected,
# minimum - Modification of targeted policy. Only selected processes are protected.
# mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF


echo "169.254.169.254 metadata.google.internal" >> /etc/hosts
mkfs.xfs -L "harbor-node" -n ftype=1 /dev/sdb
echo "/dev/sdb /var/lib/harbor xfs defaults 0 0" >> /etc/fstab
mkdir -p /var/lib/harbor
mount -a


OSTREE_REMOTE_NAME="harbor-host"
OSTREE_REMOTE_VERSION="7"
OSTREE_REMOTE_ARCH="x86_64"
OSTREE_REMOTE_BRANCH="standard"
cat > /etc/ostree/remotes.d/${OSTREE_REMOTE_NAME}.conf <<EOF
[remote "${OSTREE_REMOTE_NAME}"]
url=http://rpmostree.harboros.net:8012/repo/
gpg-verify=false
EOF
rpm-ostree rebase ${OSTREE_REMOTE_NAME}:${OSTREE_REMOTE_NAME}/${OSTREE_REMOTE_VERSION}/${OSTREE_REMOTE_ARCH}/${OSTREE_REMOTE_BRANCH} || rpm-ostree upgrade || rpm-ostree status
