#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT="OPENRC"

if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars IPA_USER_ADMIN_PASSWORD IPA_USER_ADMIN_USER
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP"
################################################################################
export IPA_SERVER=$(cat /etc/ipa/default.conf | grep "server" | awk '{print $3}')
export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
export IPA_BASE_DN=$( cat /etc/openldap/ldap.conf | grep "^BASE " | awk '{print $2}' )
export IPA_URI=$( cat /etc/openldap/ldap.conf | grep "^URI " | awk '{print $2}' )




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating openrc file for ${IPA_ADMIN_USER_NAME}@${IPA_REALM}"
################################################################################
cat > /openrc_ipa_domain << EOF
# This will scope our auth to the OS_DOMAIN_NAME domain
export OS_USERNAME=${IPA_USER_ADMIN_USER}
export OS_PASSWORD=${IPA_USER_ADMIN_PASSWORD}
export OS_DOMAIN_NAME=$IPA_REALM
#export OS_PROJECT_NAME=${DEMO_PROJECT_NAME}
#export OS_TENANT_NAME="$OS_PROJECT_NAME3"
export OS_USER_DOMAIN_NAME=${IPA_REALM}
#export OS_PROJECT_DOMAIN_NAME=${IPA_REALM}
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
export OS_IDENTITY_API_VERSION=3
export PS1="[(\$IPA_USER_ADMIN_USER@\${IPA_REALM}) \\u@\\h \\W] ⌘ "
EOF
