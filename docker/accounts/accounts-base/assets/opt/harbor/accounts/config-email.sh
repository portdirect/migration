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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring Mailer"
################################################################################
cfg=/etc/freeipa_community_portal.ini

crudini --set $cfg Mailers smtp_server "${PORTAL_SMTP_HOST}"
crudini --set $cfg Mailers smtp_port "${PORTAL_SMTP_PORT}"
crudini --set $cfg Mailers smtp_security_type "STARTTLS"
crudini --set $cfg Mailers smtp_use_auth "True"
crudini --set $cfg Mailers smtp_username "${PORTAL_SMTP_USER}"
crudini --set $cfg Mailers smtp_password "${PORTAL_SMTP_PASS}"
crudini --set $cfg Mailers default_from_email "${PORTAL_DEFAULT_FROM_EMAIL}"
crudini --set $cfg Mailers default_admin_email "${PORTAL_DEFAULT_ADMIN_EMAIL}"
