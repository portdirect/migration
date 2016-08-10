#!/bin/bash

OPENSTACK_COMPONENT=freeipa
OPENSTACK_SUBCOMPONENT=client-enroll

source /etc/os-common/common.env
source /etc/ipa/master.env
source /etc/ipa/credentials-client-provisioning.env

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Enrolling host"
################################################################################
IPA_HOST_ADMIN_USER=admin
IPA_HOST_ADMIN_PASSWORD='Password!23'
IPA_CLIENT_DEV=br0
IPA_CLIENT_IP=$(ip -f inet -o addr show $IPA_CLIENT_DEV|cut -d\  -f 7 | cut -d/ -f 1)
ipa-client-install \
    -p "$IPA_HOST_ADMIN_USER" \
    -w "$IPA_HOST_ADMIN_PASSWORD" \
    --enable-dns-updates \
    --no-ntp \
    --force-join --unattended
