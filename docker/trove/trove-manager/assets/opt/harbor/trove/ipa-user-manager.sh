#!/bin/bash
set -e
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

check_required_vars TROVE_KEYSTONE_USER TROVE_KEYSTONE_PASSWORD

check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME

dump_vars

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP"
################################################################################
export IPA_SERVER=$(cat /etc/ipa/default.conf | grep "server" | awk '{print $3}')
export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
export IPA_BASE_DN=$( cat /etc/openldap/ldap.conf | grep "^BASE " | awk '{print $2}' )
export IPA_URI=$( cat /etc/openldap/ldap.conf | grep "^URI " | awk '{print $2}' )


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP: Managing the Keystone LDAP Bind account"
################################################################################
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
  ################################################################################
  echo "${IPA_USER_ADMIN_PASSWORD}" | kinit ${IPA_USER_ADMIN_USER}

  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the keystone account"
  ################################################################################
  ipa user-show ${TROVE_KEYSTONE_USER} || (echo "${TROVE_KEYSTONE_PASSWORD}" | ipa user-add --first Trove --last OpenStack --password --shell=/sbin/nologin ${TROVE_KEYSTONE_USER})

  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ending our admin session"
  ################################################################################
  kdestroy



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: sourceing Aadmin openrc"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting cloudkitty user ID from keystone"
################################################################################
TROVE_IPA_USER_ID=$( openstack user show --domain ${IPA_REALM} ${TROVE_KEYSTONE_USER} \
                                        -f value -c id  )




SERVICES_TENANT_NAME=services
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${SERVICES_TENANT_NAME} Project"
################################################################################
ADMIN_ROLE="admin"
openstack role create --or-show \
                ${ADMIN_ROLE}

openstack project create --or-show \
                --domain ${IPA_REALM} \
                --description "${OS_DISTRO}: ${SERVICES_TENANT_NAME} project" \
                --enable \
                ${SERVICES_TENANT_NAME}

openstack role add \
                --project-domain ${IPA_REALM} \
                --user ${TROVE_IPA_USER_ID} \
                --project ${SERVICES_TENANT_NAME} \
                ${ADMIN_ROLE}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Listing the projects for which cloudkitty has the rating role"
################################################################################
openstack role assignment list --role ${ADMIN_ROLE} --user ${TROVE_IPA_USER_ID}
