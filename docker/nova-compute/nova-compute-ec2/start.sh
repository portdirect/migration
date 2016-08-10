#!/bin/bash
set -e
################################################################################
echo "${OS_DISTRO}: Nova-API: Container starting"
################################################################################
. /opt/harbor/config-nova-compute.sh
INITIAL_SLEEP_TIME=6



################################################################################
echo "${OS_DISTRO}: Nova: EC2 Container Starting"
################################################################################


ec2_dir="/usr/lib/python2.7/site-packages/nova/virt/ec2"

git clone https://github.com/stackforge/ec2-driver.git ${ec2_dir}

oldstring="nova.openstack.common import log as logging"
newstring="oslo_log import log as logging"

find ${ec2_dir} -type f -exec \
sed -i "s,$oldstring,$newstring,g" {} +


oldstring="power_state.BUILDING"
newstring="power_state.NOSTATE"

find ${ec2_dir} -type f -exec \
sed -i "s,$oldstring,$newstring,g" {} +

cfg=/etc/nova/nova.conf

crudini --set $cfg DEFAULT compute_driver "nova.virt.ec2.EC2Driver"
crudini --set $cfg conductor use_local "True"


crudini --set $cfg ec2driver ec2_access_key_id "${AWS_KEY_ID}"
crudini --set $cfg ec2driver ec2_secret_access_key "${AWS_KEY_SECRET}"

################################################################################
echo "${OS_DISTRO}: Nova-API: Sleeping for $INITIAL_SLEEP_TIME seconds"
################################################################################
sleep 6


################################################################################
echo "${OS_DISTRO}: Nova-Compute: Starting"
################################################################################
exec /usr/bin/nova-compute --config-file /etc/nova/nova.conf








