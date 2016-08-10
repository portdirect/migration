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
check_required_vars IPA_REALM IPA_USER_ADMIN_PASSWORD IPA_USER_ADMIN_USER
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token"
################################################################################
source /openrc_ipa_domain

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit ${IPA_USER_ADMIN_USER}




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Provisioning Accounts"
################################################################################
ipa stageuser-find --pkey-only | grep "^  User login: " | awk '{print $NF}' | while read STAGE_USER; do
  NEW_USERNAME=${STAGE_USER}
  echo "User: ${NEW_USERNAME}"
  USER_EMAIL="$(ipa stageuser-show $NEW_USERNAME | grep "^  Email address: " | head -n1 | awk '{print $NF}')"
  echo "Email: ${USER_EMAIL}"

  # Create a group for our user to own - using groups as a direct equiv of keystone v2 tenants
  ipa group-add --desc="Keystone Federation User Group for ${NEW_USERNAME}" "keystone-${NEW_USERNAME}"
  openstack group show --domain ${IPA_REALM} "keystone-${NEW_USERNAME}"

  # Now we need to create a keystone project, and give our user access to it via their group
  KEYSTONE_PROJECT=${NEW_USERNAME}
  openstack project create --or-show --domain ${IPA_REALM} --description "${OS_DOMAIN} project for ${NEW_USERNAME}" ${KEYSTONE_PROJECT}
  openstack role add --project-domain ${IPA_REALM} --project ${KEYSTONE_PROJECT} --group-domain ${IPA_REALM} --group "keystone-${NEW_USERNAME}" user

  # Now the env is prepped for our user lets activate them, remove them from the ipa-users group and add them to their own group
  ipa stageuser-activate ${NEW_USERNAME}
  ipa group-remove-member "ipausers" --users "${NEW_USERNAME}"
  ipa group-add-member "keystone-${NEW_USERNAME}" --users "${NEW_USERNAME}"

  EMAIL_UUID=$(uuidgen)
  # Tell the user the good news, that they can get going!
  sed "s/{{ USER }}/${NEW_USERNAME}/" /srv/mail/blank-slate/conv.html > /tmp/welcome-${EMAIL_UUID}
  mutt -e "set sendmail=/usr/sbin/ssmtp" \
  -e "set content_type=text/html" \
  -e "set use_from=yes" \
  -e "set from=${PORTAL_DEFAULT_FROM_EMAIL}" \
  -e "set realname=\"${OS_DOMAIN}\"" \
  ${USER_EMAIL} -s "Welcome to ${OS_DOMAIN}" < /tmp/welcome-${EMAIL_UUID}
  rm -f /tmp/welcome-${EMAIL_UUID}
done
