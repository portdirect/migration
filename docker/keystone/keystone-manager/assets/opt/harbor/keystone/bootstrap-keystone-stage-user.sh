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


export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit ${IPA_USER_ADMIN_USER}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Provisioning Accounts"
################################################################################
ipa stageuser-find | grep "^  User login: " | awk '{print $NF}' | while read STAGE_USER; do
  NEW_USERNAME=${STAGE_USER}
  echo "User: ${NEW_USERNAME}"
  USER_EMAIL="$(ipa stageuser-show $NEW_USERNAME | grep "^  Email address: " | head -n1 | awk '{print $NF}')"
  echo "Email: ${USER_EMAIL}"
  ipa group-add --desc="Keystone Federation User Group for ${NEW_USERNAME}" "keystone-${NEW_USERNAME}"
  openstack group show --domain ${IPA_REALM} "keystone-${NEW_USERNAME}"
  KEYSTONE_PROJECT=${NEW_USERNAME}
  openstack project create --or-show --domain ${IPA_REALM} --description "${OS_DOMAIN} project for ${NEW_USERNAME}" ${KEYSTONE_PROJECT}
  openstack role add --project-domain ${IPA_REALM} --project ${KEYSTONE_PROJECT} --group-domain ${IPA_REALM} --group "keystone-${NEW_USERNAME}" user
  ipa stageuser-activate ${NEW_USERNAME}
  ipa group-remove-member "ipausers" --users "${NEW_USERNAME}"
  ipa group-add-member "keystone-${NEW_USERNAME}" --users "${NEW_USERNAME}"
  ipa user-show ${NEW_USERNAME}
done
