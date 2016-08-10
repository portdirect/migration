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
check_required_vars IPA_USER_ADMIN_PASSWORD IPA_USER_ADMIN_USER \
                    GRAFANA_LDAP_PASSWORD GRAFANA_LDAP_USER IPA_DS_PASSWORD
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo \"${IPA_USER_ADMIN_PASSWORD}\" | kinit ${IPA_USER_ADMIN_USER}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the roles for grafana"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa privilege-show 'Grafana management privilege' || ipa privilege-add 'Grafana management privilege' --desc 'Grafana privileges'"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Fixing Permissions"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa permission-mod 'System: Read User Addressbook Attributes' --bindtype=permission || echo \"Failed to set Address Book read to permission bind\""
#ipa permission-mod 'System: Read User Standard Attributes' --bindtype=permission || echo "Failed to set Read Standard Attrs to permission bind"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Kesystone privileges"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa privilege-add-permission 'Grafana management privilege' \
--permission='System: Read User Addressbook Attributes' || echo 'Did not add any new permissions to the grafana management privilege'"
# ipa privilege-add-permission 'Keystone management privilege' \
#     --permission='System: Read User Standard Attributes' || echo "Did not add any new permissions to the grafana management privilege"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Kesystone role"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa role-show 'Grafana management' || ipa role-add 'Grafana management' --desc='Grafana Management Role'"
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa role-add-privilege 'Grafana management' --privilege='Grafana management privilege' || echo 'Did not add any new privileges to the grafana management role'"
#

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the grafana account"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "(echo \"${GRAFANA_LDAP_PASSWORD}\" | ipa user-add --first Grafana --last OpenStack --password --shell=/sbin/nologin ${GRAFANA_LDAP_USER}) || echo 'Did not create a FreeIPA user account'"
export GRAFANA_LDAP_BIND_DN="uid=${GRAFANA_LDAP_USER},cn=users,cn=accounts,$IPA_BASE_DN"


# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP: Managing the LDAP Bind account"
# ################################################################################
# docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ldapmodify -x -D 'cn=Directory Manager' -w${IPA_DS_PASSWORD}  <<EOF
# dn: uid=${GRAFANA_LDAP_USER},cn=sysaccounts,cn=etc,dc=port,dc=direct
# changetype: delete
#
# EOF" || true
# docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ldapmodify -x -D 'cn=Directory Manager' -w${IPA_DS_PASSWORD}  <<EOF
# dn: uid=${GRAFANA_LDAP_USER},cn=sysaccounts,cn=etc,dc=port,dc=direct
# changetype: add
# objectclass: account
# objectclass: simplesecurityobject
# uid: ${GRAFANA_LDAP_USER}
# userPassword: ${GRAFANA_LDAP_PASSWORD}
# passwordExpirationTime: 20380119031407Z
# nsIdleTimeout: 0
#
# EOF"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Adding the grafana user to the grafana role"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa role-add-member --users=${GRAFANA_LDAP_USER} 'Grafana management' || echo \"Did not add ${GRAFANA_LDAP_USER} to the Keystone management role\""


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ending our admin session"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP: Checking we can get users from IPA"
################################################################################
docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ldapsearch \
    -h $IPA_SERVER -p 389 -x -u \
    -D \"$GRAFANA_LDAP_BIND_DN\" \
    -w \"${GRAFANA_LDAP_PASSWORD}\" \
    -b cn=users,cn=accounts,$IPA_BASE_DN \
    \"uid=${GRAFANA_LDAP_USER}\""
