#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=keystone
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
sed -i "s,^#OPENSTACK_SSL_CACERT = '/path/to/cacert.pem',OPENSTACK_SSL_CACERT = '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem'," $cfg
sed -i "s/#CSRF_COOKIE_SECURE = True/CSRF_COOKIE_SECURE = True/g" $cfg
sed -i "s/#SESSION_COOKIE_SECURE = True/SESSION_COOKIE_SECURE = True/g" $cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Allowed Hosts"
################################################################################
sed -i "s/horizon.example.com/*/g" $cfg
