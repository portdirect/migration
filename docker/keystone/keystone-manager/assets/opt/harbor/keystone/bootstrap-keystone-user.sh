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
check_required_vars KEYSTONE_ADMIN_TOKEN \
                    KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_ADMIN_SERVICE_PORT \
                    KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_PORT \
                    IPA_REALM
dump_vars





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue


export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')






ITERATION=42
NEW_USERNAME="test${ITERATION}"
NEW_PASSWORD="acomanacoman"
NEW_FIRSTNAME="firstname${ITERATION}"
NEW_LASTNAME="lastname${ITERATION}"
NEW_EMAIL="test${ITERATION}@example.com"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit ${IPA_USER_ADMIN_USER}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the FreeIPA ACCOUNT"
################################################################################
echo "${NEW_PASSWORD}" | ipa user-add --first ${NEW_FIRSTNAME} --last ${NEW_LASTNAME} --password --shell=/bin/bash ${NEW_USERNAME}
ipa group-add --desc="Keystone Federation User Group for ${NEW_USERNAME}" "keystone-${NEW_USERNAME}"
ipa group-add-member "keystone-${NEW_USERNAME}" --users "${NEW_USERNAME}"
ipa group-remove-member "ipausers" --users "${NEW_USERNAME}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the Keystone PROJECT"
################################################################################
KEYSTONE_PROJECT=${NEW_USERNAME}
openstack group show --domain ${IPA_REALM} "keystone-${NEW_USERNAME}"
openstack project create --or-show --domain ${IPA_REALM} --description "${OS_DOMAIN} project for ${NEW_USERNAME}" ${KEYSTONE_PROJECT}
openstack role add --project-domain ${IPA_REALM} --project ${KEYSTONE_PROJECT} --group-domain ${IPA_REALM} --group "keystone-${NEW_USERNAME}" user


# openstack group list --domain PORT.DIRECT ipausers
# openstack project create --domain PORT.DIRECT ipausers
# openstack role add --project-domain PORT.DIRECT --project ipausers --group-domain PORT.DIRECT --group ipausers user
#
# openstack group show --domain PORT.DIRECT test-project
# openstack project create --domain PORT.DIRECT test-project
# openstack role add --project-domain PORT.DIRECT --project test-project --group-domain PORT.DIRECT --group test-project user
#
# openstack group show --domain PORT.DIRECT test-project
# openstack project create --domain PORT.DIRECT test-project2
# openstack role add --project-domain PORT.DIRECT --project test-project2 --group-domain PORT.DIRECT --group test-project user
