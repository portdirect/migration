#!/bin/bash
set -e
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
. /opt/harbor/harbor-common.sh




################################################################################
echo "${OS_DISTRO}: Swift: Managing system users "
################################################################################

# Ensure proper ownership of the mount point directory structure
mkdir -p /var/lib/swift
groupadd -g 160 swift || true
useradd --system -u 160 -g swift --shell /sbin/nologin --home-dir /var/lib/swift swift || true
chown swift:swift /srv/node
chown swift:swift /srv/node/*
chown -R swift:swift /var/lib/swift
chown -R swift:swift /srv/pod || true


cfg=/etc/rsyncd.conf
SWIFT_DEVICE_IP_ADDRESS=$(ip -f inet -o addr show $SWIFT_DEVICE|cut -d\  -f 7 | cut -d/ -f 1)

cat > $cfg <<EOF
uid = swift
gid = swift
log file = /dev/stdout
pid file = /var/run/rsyncd.pid
address = ${SWIFT_DEVICE_IP_ADDRESS}

[account]
max connections = 2
path = /srv/node/
read only = false
lock file = /srv/pod/account.lock

[container]
max connections = 2
path = /srv/node/
read only = false
lock file = /srv/pod/container.lock

[object]
max connections = 2
path = /srv/node/
read only = false
lock file = /srv/pod/object.lock
EOF

CMD="/usr/bin/rsync"
ARGS="--daemon --config=$cfg --no-detach --address=$SWIFT_DEVICE_IP_ADDRESS --verbose --bwlimit=20000"

################################################################################
echo "${OS_DISTRO}: Swift: Rsync: Launching ($CMD $ARGS) "
################################################################################
exec $CMD $ARGS
