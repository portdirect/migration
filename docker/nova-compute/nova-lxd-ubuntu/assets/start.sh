#!/bin/bash
set -e
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Loading Apparmor if supported"
################################################################################
/usr/lib/x86_64-linux-gnu/lxc/lxc-apparmor-load
#/usr/lib/lxd/lxd-bridge start
(
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching LXD Setup"
################################################################################
for i in $(seq 30); do lxc finger --force-local >/dev/null 2>&1 && break; sleep 1; done
/usr/lib/lxd/profile-config
/usr/bin/lxd waitready
)&
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching LXD"
################################################################################
/usr/bin/lxd --logfile=/var/log/lxd.log --debug



# lxc config set core.https_address [::]:8443
# lxc config set core.trust_password something-secure
# lxc remote add host-a --accept-certificate=true --password="something-secure" 10.140.50.150
# lxc remote add host-b --accept-certificate=true --password="something-secure" 10.140.38.147
# lxc remote add host-c --accept-certificate=true --password="something-secure" 10.140.63.249
