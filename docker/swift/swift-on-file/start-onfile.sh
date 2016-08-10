#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

tail -f /dev/null

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/config-swift.sh



CMD="/usr/bin/swift-account-server"
ARGS="/etc/swift/account-server.conf --verbose"


################################################################################
echo "${OS_DISTRO}: Swift: Account Server: Configuration"
################################################################################
cfg=/etc/swift/account-server.conf

crudini --set $cfg DEFAULT bind_ip "0.0.0.0"
crudini --set $cfg DEFAULT bind_port "6002"
crudini --set $cfg DEFAULT user "swift"
crudini --set $cfg DEFAULT swift_dir "/etc/swift"
crudini --set $cfg DEFAULT devices "/mnt/os-swift"
crudini --set $cfg DEFAULT mount_check "false"

crudini --set $cfg pipeline:main pipeline "healthcheck recon account-server"

crudini --set $cfg filter:recon use "egg:swift#recon"
crudini --set $cfg filter:recon recon_cache_path "/var/cache/swift"


################################################################################
echo "${OS_DISTRO}: Swift: Managing system users "
################################################################################

# Create swift user and group if they don't exist
id -u swift &>/dev/null || useradd --user-group swift

# Ensure proper ownership of the mount point directory structure
chown -R swift:swift /mnt/os-swift

echo "${OS_DISTRO}: Swift: Launching ($CMD $ARGS) "
################################################################################
exec $CMD $ARGS
