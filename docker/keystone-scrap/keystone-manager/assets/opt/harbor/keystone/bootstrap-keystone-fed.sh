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



# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Looping back primary keystone API to localhost"
################################################################################
/bin/cp -f /etc/hosts /etc/hosts-original
echo "127.0.0.1       ${KEYSTONE_ADMIN_SERVICE_HOST}" >> /etc/hosts
echo "127.0.0.1       ${KEYSTONE_PUBLIC_SERVICE_HOST}" >> /etc/hosts


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining Service Endoints"
################################################################################
# Export Keystone service environment variables
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="https://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
httpd -k start

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying Keystone is running"
################################################################################
while ! curl -o /dev/null -s --fail ${SERVICE_ENDPOINT}; do
    echo "${OS_DISTRO}: Waiting for Keystone @ ${SERVICE_ENDPOINT}"
    httpd -k start
    sleep 1;
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ipausers Project"
################################################################################
openstack project create --or-show \
                --domain default \
                --description "${OS_DISTRO}: ipausers project" \
                --enable \
                ipausers


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up ipsilon as an id provider"
################################################################################
openstack group create --domain default --description "${OS_DISTRO}: ipausers admins" --or-show admins
openstack group create --domain default --description "${OS_DISTRO}: ipausers users" --or-show ipausers
openstack role add  --project ipausers --group ipausers user


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up ipsilon as an id provider"
################################################################################
openstack identity provider show ipslion || \
    openstack identity provider create --remote-id https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata ipsilon

openstack mapping show ipsilon_mapping || \
    openstack --debug mapping create --rules /etc/keystone/disabled/mapping_ipsilon_saml2.json ipsilon_mapping

openstack federation protocol show --identity-provider ipsilon saml2 || \
    openstack federation protocol create --identity-provider ipsilon --mapping ipsilon_mapping saml2



openstack identity provider create sssd
openstack mapping create  --rules /home/cloud-user/mapping.json  kerberos_mapping
openstack federation protocol create --identity-provider sssd --mapping kerberos_mapping kerberos
openstack identity provider set --remote-id SSSD sssd


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Stopping Local Server"
################################################################################
httpd -k stop
/bin/cp -f /etc/hosts-original /etc/hosts


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token from the real keystone servers"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue
