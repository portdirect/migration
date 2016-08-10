#!/bin/sh
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

systemctl start docker
docker pull docker.io/port/system-installer:latest
docker run \
       --privileged=true \
       -v /:/host \
       -t \
       --net=host \
       docker.io/port/system-installer:latest /init

#Reload systemd units, remove the inital docker graph directory, and make sure firewalld is not running:
systemctl daemon-reload
systemctl stop docker
rm -rf /var/lib/docker/
systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld
systemctl mask rpcbind.service


echo "169.254.169.254 metadata.google.internal" >> /etc/hosts
mkfs.xfs -L "harbor-node" -n ftype=1 /dev/sdb
echo "/dev/sdb /var/lib/harbor xfs defaults 0 0" >> /etc/fstab
mkdir -p /var/lib/harbor
mount -a
sed -i 's/%wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tNOPASSWD: ALL/g' /etc/sudoers



mkdir -p /etc/harbor
cat > /etc/harbor/network.env <<EOF
OS_DOMAIN=port.direct
EXTERNAL_DNS=8.8.8.8
EXTERNAL_DNS_1=8.8.4.4
DOCKER_BOOTSTRAP_NETWORK=172.17.42.1/16
EOF
