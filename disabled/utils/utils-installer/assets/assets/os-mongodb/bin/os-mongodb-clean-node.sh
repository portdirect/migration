#!/bin/bash


OPENSTACK_COMPONENT=os-mongodb
OPENSTACK_SUBCOMPONENT=cleaner

source /etc/os-common/common.env
source /etc/os-mongodb/os-mongodb.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing Data From Host"
################################################################################
rm -rf ${OS_DATABASE_MONGODB_DIR}/*
