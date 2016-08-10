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
check_required_vars KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_HOST
dump_vars



# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up database"
################################################################################
/opt/harbor/keystone/config-database.sh
#/opt/harbor/keystone/drop-db.sh
/opt/harbor/keystone/create-db.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up endpoints"
################################################################################
/opt/harbor/keystone/ipa-endpoint-manager.sh




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS -For bootstrapping"
################################################################################
SVC_AUTH_ROOT_LOCAL_CONTAINER=/etc/harbor/auth
OPENSTACK_KUBE_SVC_NAME="keystone"
mkdir -p ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}
KUBE_SVC_KEY_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.key
KUBE_SVC_CRT_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.crt
KUBE_SVC_CA_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/ca.crt
mkdir -p /etc/pki/tls/private
cat ${KUBE_SVC_KEY_LOC} > /etc/pki/tls/private/ca.key
mkdir -p /etc/pki/tls/certs
cat ${KUBE_SVC_CRT_LOC} > /etc/pki/tls/certs/ca.crt



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing TOKENS"
################################################################################
/opt/harbor/keystone/token-manager.sh
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /var/log/keystone


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing DOMAINS"
################################################################################
/opt/harbor/keystone/config-domains.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Bootstrapping keystone"
################################################################################
/opt/harbor/keystone/bootstrap-keystone.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: IPSILON"
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying IPSILON is running"
while ! curl -o /dev/null -s --fail https://ipsilon.${OS_DOMAIN}/idp/login/form; do
    echo "${OS_DISTRO}: Waiting for IPSILON @ https://ipsilon.${OS_DOMAIN}/idp/login/form"
    sleep 10s;
done

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting UP SPs"
################################################################################
/opt/harbor/keystone/ipsilon-websso-manager.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Metadata from Ipsilon"
################################################################################
mkdir -p /etc/httpd/saml2
curl -L https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata > /etc/httpd/saml2/idp-metadata.xml


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting for API servers to come online"
################################################################################
SERVICE_ENDPOINT="https://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"
while ! curl -o /dev/null -s --fail ${SERVICE_ENDPOINT}; do
    echo "${OS_DISTRO}: Waiting for Keystone @ ${SERVICE_ENDPOINT}"
    sleep 10s;
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Bootstrapping keystone ${OS_DOMAIN} domain"
################################################################################
/opt/harbor/keystone/bootstrap-keystone-domain.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Bootstrapping keystone Federation"
################################################################################
/opt/harbor/keystone/bootstrap-keystone-fed.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Primary API Management Complete"
################################################################################


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up endpoints for legacy keystone v2"
################################################################################
/opt/harbor/keystone/ipa-endpoint-manager-v2-default.sh
