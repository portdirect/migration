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
: ${DESIGNATE_POOL_ID:="794ccc2c-d751-44fe-b57f-8894c9f5c842"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars DESIGNATE_POOL_DB_PASSWORD DESIGNATE_POOL_DB_NAME DESIGNATE_POOL_DB_USER \
                    MARIADB_SERVICE_HOST DB_ROOT_PASSWORD

check_required_vars DESIGNATE_PDNS_DB_PASSWORD DESIGNATE_PDNS_DB_NAME DESIGNATE_PDNS_DB_USER \
                    MARIADB_SERVICE_HOST DB_ROOT_PASSWORD
dump_vars



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${DESIGNATE_POOL_DB_NAME}
fail_unless_db ${DESIGNATE_PDNS_DB_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating POOL INFO"
################################################################################
su -s /bin/sh -c "/usr/bin/designate-manage pool update" designate


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Showing POOL INFO"
################################################################################
su -s /bin/sh -c "/usr/bin/designate-manage pool show_config" designate


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Initializing the Power DNS DB"
################################################################################
su -s /bin/sh -c "designate-manage --debug powerdns sync ${DESIGNATE_POOL_ID}" designate


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting DB Version"
################################################################################
su -s /bin/sh -c "designate-manage --debug powerdns version ${DESIGNATE_POOL_ID}" designate
