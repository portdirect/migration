#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=federation
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg OS_DOMAIN


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: OS-FEDERATION"
################################################################################
# Set up Keystone for OS-FEDERATION extension
crudini --set $cfg auth methods "external,password,token,saml2"
#crudini --set $cfg auth saml2 keystone.auth.plugins.mapped.Mapped
#crudini --set $cfg auth kerberos keystone.auth.plugins.mapped.Mapped


#crudini --set $cfg federation sso_callback_template /etc/keystone/sso_callback_template.html
crudini --set $cfg federation remote_id_attribute MELLON_IDP
crudini --set $cfg federation trusted_dashboard "https://api.${OS_DOMAIN}/auth/websso/"
