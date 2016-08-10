#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=email
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

: ${IPA_PORTAL_USER:="portal"}

IPA_SERVER=$(cat /etc/ipa/default.conf | grep "server" | awk '{print $3}')
IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
IPA_BASE_DN=$( cat /etc/openldap/ldap.conf | grep "^BASE " | awk '{print $2}' )
IPA_URI=$( cat /etc/openldap/ldap.conf | grep "^URI " | awk '{print $2}' )


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit ${IPA_USER_ADMIN_USER}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Retriving Keytab"
################################################################################
mkdir -p /etc/ipa
ipa-getkeytab -s ${IPA_SERVER} -p ${IPA_PORTAL_USER}@${IPA_REALM} -k /etc/ipa/${IPA_PORTAL_USER}.keytab
chown apache:apache /etc/ipa/${IPA_PORTAL_USER}.keytab

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ending our admin session"
################################################################################
kdestroy
