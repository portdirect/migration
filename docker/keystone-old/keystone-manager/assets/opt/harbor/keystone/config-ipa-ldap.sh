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
. /opt/harbor/keystone-vars.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars IPA_USER_ADMIN_PASSWORD IPA_USER_ADMIN_USER \
                    KEYSTONE_LDAP_PASSWORD KEYSTONE_LDAP_USER
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
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the roles for keystone"
  ################################################################################
  ipa privilege-show 'Keystone management privilege' || ipa privilege-add 'Keystone management privilege' --desc 'Keystone privileges'
  #
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Fixing Permissions"
  ################################################################################
  ipa permission-mod 'System: Read User Addressbook Attributes' --bindtype=permission || echo "Failed to set Address Book read to permission bind"
  #ipa permission-mod 'System: Read User Standard Attributes' --bindtype=permission || echo "Failed to set Read Standard Attrs to permission bind"
  #
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Kesystone privileges"
  ################################################################################
  ipa privilege-add-permission 'Keystone management privilege' \
      --permission='System: Read User Addressbook Attributes' || echo "Did not add any new permissions to the keystone management privilege"
  # ipa privilege-add-permission 'Keystone management privilege' \
  #     --permission='System: Read User Standard Attributes' || echo "Did not add any new permissions to the keystone management privilege"
  #
  #
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Kesystone role"
  ################################################################################
  ipa role-show 'Keystone management' || ipa role-add 'Keystone management' --desc="Keystone Management Role"
  #
  # ipa role-add-privilege 'Keystone management' --privilege='Keystone management privilege' || echo "Did not add any new privileges to the keystone management role"
  #

  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the keystone account"
  ################################################################################
  (echo "${KEYSTONE_LDAP_PASSWORD}" | ipa user-add --first Keystone --last OpenStack --password --shell=/sbin/nologin ${KEYSTONE_LDAP_USER}) || echo "Did not create a FreeIPA user account"
  export KEYSTONE_LDAP_BIND_DN="uid=${KEYSTONE_LDAP_USER},cn=users,cn=accounts,$IPA_BASE_DN"


  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Adding the keystone user to the keystone role"
  ################################################################################
  ipa role-add-member --users=${KEYSTONE_LDAP_USER} 'Keystone management' || echo "Did not add ${KEYSTONE_LDAP_USER} to the Keystone management role"


  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ending our admin session"
  ################################################################################
  kdestroy

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP: Checking we can get users from IPA"
################################################################################
ldapsearch \
    -h $IPA_SERVER -p 389 -x -u \
    -D "$KEYSTONE_LDAP_BIND_DN" \
    -w "${KEYSTONE_LDAP_PASSWORD}" \
    -b cn=users,cn=accounts,$IPA_BASE_DN \
    "uid=${KEYSTONE_LDAP_USER}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP: Defining ${IPA_REALM} domain"
################################################################################
mkdir -p /etc/keystone/domains
cat > /etc/keystone/domains/keystone.${IPA_REALM}.conf << EOF
[identity]
driver = keystone.identity.backends.ldap.Identity

[ldap]
url=$IPA_URI
user=$KEYSTONE_LDAP_BIND_DN
password=${KEYSTONE_LDAP_PASSWORD}
suffix=$IPA_BASE_DN
user_tree_dn=cn=users,cn=accounts,$IPA_BASE_DN
user_objectclass=person
user_id_attribute=uid
user_name_attribute=uid
user_mail_attribute=mail
user_allow_create=false
user_allow_update=false
user_allow_delete=false

group_tree_dn=cn=groups,cn=accounts,$IPA_BASE_DN
group_objectclass=groupOfNames
group_id_attribute=cn
group_name_attribute=cn
group_member_attribute=member
group_desc_attribute=description
group_allow_create=false
group_allow_update=false
group_allow_delete=false

user_enabled_attribute=nsAccountLock
user_enabled_default=False
user_enabled_invert=true

EOF
chown -R keystone:keystone /etc/keystone/domains


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating $IPA_REALM domain"
################################################################################
IPA_REALM_DESCRIPTION="${IPA_REALM} user domain"
openstack domain create --description "${IPA_REALM_DESCRIPTION}" --enable ${IPA_REALM} \
    || openstack --os-identity-api-version 3 \
          domain show ${IPA_REALM}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Uploading the $IPA_REALM domain config"
################################################################################
keystone-manage --debug --verbose domain_config_upload --domain-name $IPA_REALM \
    || echo "Did not upload config"




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting the $IPA_USER_ADMIN_USER@$IPA_REALM user ID"
################################################################################
IPA_ADMIN_USER_ID=$( openstack user show --domain $IPA_REALM $IPA_USER_ADMIN_USER \
                                        -f value -c id  )
openstack user show $IPA_ADMIN_USER_ID
