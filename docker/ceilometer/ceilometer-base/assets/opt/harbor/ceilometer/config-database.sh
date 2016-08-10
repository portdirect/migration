#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=database
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MONGODB_SERVICE_HOST \
                        CEILOMETER_DB_USER CEILOMETER_DB_PASSWORD CEILOMETER_DB_NAME


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
#[database]

#
# Options defined in ceilometer.storage
#

# Number of seconds that samples are kept in the database for
# (<= 0 means forever). (integer value)
#time_to_live=-1

# The connection string used to connect to the meteting
# database. (if unset, connection is used) (string value)
#metering_connection=<None>

# The connection string used to connect to the alarm database.
# (if unset, connection is used) (string value)
#alarm_connection=<None>
crudini --set $cfg database connection "mongodb://${CEILOMETER_DB_USER}:${CEILOMETER_DB_PASSWORD}@${MONGODB_SERVICE_HOST}:27017/${CEILOMETER_DB_NAME}"
