#!/bin/bash
set -o errexit

################################################################################
echo "${OS_DISTRO}: Memcached: Container starting"
################################################################################
# Loading common functions.
source /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: Memcached: Launching"
################################################################################
CMD="/usr/bin/memcached"
ARGS="-u memcached -vv"
exec $CMD $ARGS
