#!/bin/bash
set -e
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking CRIU"
################################################################################
criu check || true

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking LXC"
################################################################################
( lxc-checkconfig ) || true

#lxc-create -n MyCentOSContainer1 -t /usr/local/share/lxc/templates/lxc-centos
#ROOT_RASSWORD=$(cat /usr/local/var/lib/lxc/MyCentOSContainer1/tmp_root_pass)

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating LXC Bridge"
################################################################################
brctl addbr lxcbr0 || true
/opt/lxd/src/github.com/lxc/lxd/lxd-bridge/lxd-bridge start


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching LXD Setup"
################################################################################
(
for i in $(seq 30); do lxc finger --force-local >/dev/null 2>&1 && break; sleep 1; done
/usr/bin/lxd init --auto --network-address=127.0.0.1 --network-port=8443 --storage-backend=dir --trust-password="heyheyheyhey"
/usr/bin/lxd waitready
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LXD READY"
################################################################################
)&

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching LXD"
################################################################################
/usr/bin/lxd daemon --group=root

# lxc config set core.https_address [::]:8443
# lxc config set core.trust_password something-secure
# lxc remote add host-a --accept-certificate=true --password="something-secure" 10.140.50.150
# lxc remote add host-b --accept-certificate=true --password="something-secure" 10.140.38.147
# lxc remote add host-c --accept-certificate=true --password="something-secure" 10.140.63.249
