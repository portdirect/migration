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

check_required_vars CLOUDKITTY_FREEIPA_USER CLOUDKITTY_FREEIPA_PASSWORD

check_required_vars KEYSTONE_ADMIN_USER KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DEFINING IPA DOCKER INTERACTION"
################################################################################
FREEIPA_CONTAINER_NAME=$(cat /etc/ipa/default.conf | grep "^server =" | awk '{print $NF}' | sed "s/.${OS_DOMAIN}//")


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP: Managing the Keystone LDAP Bind account"
################################################################################
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
  ################################################################################
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo \"${IPA_USER_ADMIN_PASSWORD}\" | kinit ${IPA_USER_ADMIN_USER}"

  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the keystone account"
  ################################################################################
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa user-show ${CLOUDKITTY_FREEIPA_USER} || (echo \"${CLOUDKITTY_FREEIPA_PASSWORD}\" | ipa user-add --first CloudKitty --last OpenStack --password --shell=/sbin/nologin ${CLOUDKITTY_FREEIPA_USER})"

  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ending our admin session"
  ################################################################################
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing admin credentials for ${KEYSTONE_ADMIN_USER}"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting cloudkitty user ID from keystone"
################################################################################
CLOUDKITTY_IPA_USER_ID=$( openstack user show --domain ${IPA_REALM} ${CLOUDKITTY_FREEIPA_USER} \
                                        -f value -c id  )




SERVICES_TENANT_NAME=services
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${SERVICES_TENANT_NAME} Project"
################################################################################
ADMIN_ROLE="admin"
openstack role create --or-show \
                ${ADMIN_ROLE}


openstack role add \
    --project-domain default \
    --user ${CLOUDKITTY_IPA_USER_ID} \
    --project ${SERVICES_TENANT_NAME} \
    ${ADMIN_ROLE}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Applying the rating role to each project in the IPA realm"
################################################################################
RATING_ROLE="rating"
openstack role create --or-show \
                ${RATING_ROLE}

openstack project list \
          --domain ${IPA_REALM} \
          -f value \
          -c ID | \
        while read PROJECT; do
          openstack role add \
                --user ${CLOUDKITTY_IPA_USER_ID} \
                --project ${PROJECT} \
                ${RATING_ROLE}
        done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Listing the projects for which cloudkitty has the rating role"
################################################################################
openstack role assignment list --role ${RATING_ROLE} --user ${CLOUDKITTY_IPA_USER_ID}
