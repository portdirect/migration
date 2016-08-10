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
. /opt/harbor/config-swift.sh




################################################################################
echo "${OS_DISTRO}: Swift: Managing system users "
################################################################################

# Create swift user and group if they don't exist
id -u swift &>/dev/null || useradd --user-group swift

# Ensure proper ownership of the mount point directory structure
chown -R swift:swift /srv/node



cfg=/etc/rsyncd.conf


MANAGEMENT_INTERFACE_IP_ADDRESS=$(ip -f inet -o addr show $SWIFT_MANAGEMENT_INTERFACE|cut -d\  -f 7 | cut -d/ -f 1)


cat > $cfg <<EOF
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = ${MANAGEMENT_INTERFACE_IP_ADDRESS}

[account]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
EOF

CMD="/usr/bin/rsync"
ARGS="--daemon --config=$cfg --no-detach --address=$MANAGEMENT_INTERFACE_IP_ADDRESS --verbose --bwlimit=20000"

################################################################################
echo "${OS_DISTRO}: Swift: Rsync: Launching ($CMD $ARGS) "
################################################################################
exec $CMD $ARGS
