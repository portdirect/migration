#!/bin/bash


OPENSTACK_COMPONENT=os-database
OPENSTACK_SUBCOMPONENT=cleaner

source /etc/os-common/common.env
source /etc/os-database/os-database.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing Data From Host"
################################################################################
rm -rf ${OS_DATABASE_DIR}/*
