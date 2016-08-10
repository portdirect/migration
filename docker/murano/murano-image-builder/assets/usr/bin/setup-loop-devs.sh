#!/bin/bash
set -e
################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up loop devices"
################################################################################
ensure_loop(){
  num="$1"
  dev="/dev/loop$num"
  if test -b "$dev"; then
    echo "$dev is a usable loop device."
    return 0
  fi

  echo "Attempting to create $dev for docker ..."
  if ! mknod -m660 $dev b 7 $num; then
    echo "Failed to create $dev!" 1>&2
    return 3
  fi

  return 0
}

LOOP_A=$(losetup -f)
LOOP_A=${LOOP_A#/dev/loop}
LOOP_B=$(expr $LOOP_A + 1)
ensure_loop $LOOP_A
ensure_loop $LOOP_B

dmsetup --noudevsync mknodes
