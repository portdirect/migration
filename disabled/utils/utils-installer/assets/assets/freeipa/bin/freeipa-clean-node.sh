#!/bin/bash


OPENSTACK_COMPONENT=freeipa
OPENSTACK_SUBCOMPONENT=cleaner

source /etc/os-common/common.env
source /etc/ipa/master.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing Data From Host"
################################################################################
rm -rf ${IPA_DATA_DIR}/*
