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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating openrc file for ${KEYSTONE_ADMIN_USER}"
################################################################################
cat > /openrc_${KEYSTONE_ADMIN_USER}-default <<EOF
export OS_USERNAME=${KEYSTONE_ADMIN_USER}
export OS_PASSWORD=${KEYSTONE_ADMIN_PASSWORD}
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=${DEFAULT_REGION}
export OS_PROJECT_NAME=${KEYSTONE_ADMIN_PROJECT}
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_CACERT=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
export PS1="[(\${OS_USERNAME}@\${OS_PROJECT_DOMAIN_NAME}/\${OS_PROJECT_NAME}) \\u@\\h \\W] ⌘ "
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting a token for ${KEYSTONE_ADMIN_USER}"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue
