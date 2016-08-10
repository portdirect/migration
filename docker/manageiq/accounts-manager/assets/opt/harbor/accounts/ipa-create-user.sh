#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=email
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit ${IPA_USER_ADMIN_USER}


# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Fixing IPA Permissions"
# ################################################################################
# ipa permission-mod 'System: Read User Addressbook Attributes' --bindtype=permission || echo "Failed to set permission"
# ipa permission-mod 'System: Read User Standard Attributes' --bindtype=permission || echo "Failed to set permission"
# ipa permission-mod 'System: Read Stage Users' --bindtype=permission || echo "Failed to set permission"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating Portal User"
################################################################################
/usr/bin/create-portal-user

ipa privilege-add-permission 'Portal management privilege' \
    --permission='System: Read Stage Users' ||  echo "Failed to set privilege"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ending our admin session"
################################################################################
kdestroy
