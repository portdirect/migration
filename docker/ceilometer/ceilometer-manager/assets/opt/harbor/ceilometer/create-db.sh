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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars MONGODB_SERVICE_HOST \
                    CEILOMETER_DB_USER CEILOMETER_DB_PASSWORD CEILOMETER_DB_NAME
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Cache"
################################################################################
mongo --host ${MONGODB_SERVICE_HOST} --port 27017 --eval "
  db = db.getSiblingDB(\"${CEILOMETER_DB_NAME}\");
  db.createUser({user: \"${CEILOMETER_DB_USER}\",
  pwd: \"${CEILOMETER_DB_PASSWORD}\",
  roles: [ \"readWrite\", \"dbAdmin\" ]})" || echo "Need to test if user exists"
