#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=glance
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg GLANCE_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Glance"
################################################################################
crudini --set $cfg DEFAULT glance_host "${GLANCE_API_SERVICE_HOST}"
crudini --set $cfg DEFAULT glance_port "443"
crudini --set $cfg DEFAULT glance_api_servers "${KEYSTONE_AUTH_PROTOCOL}://${GLANCE_API_SERVICE_HOST}:443"
#crudini --set $cfg DEFAULT glance_api_version "1"
crudini --set $cfg DEFAULT glance_api_insecure "false"
crudini --set $cfg DEFAULT glance_api_ssl_compression "true"
crudini --set $cfg DEFAULT glance_ca_certificates_file "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
#crudini --set $cfg DEFAULT glance_request_timeout "30"
