#!/bin/bash
set -e
tail -f /dev/null
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: OS-FEDERATION"
################################################################################
# Set up Keystone for OS-FEDERATION extension
crudini --set $cfg federation driver "keystone.contrib.federation.backends.sql.Federation"
crudini --set $cfg auth methods "external,password,token,saml2"
crudini --set $cfg auth saml2 "keystone.auth.plugins.mapped.Mapped"
crudini --set $cfg federation remote_id_attribute "MELLON_IDP"
crudini --set $cfg federation trusted_dashboard "https://api.${OS_DOMAIN}/auth/websso/"
v3_pipeline="$(crudini --get /etc/keystone/keystone-paste.ini pipeline:api_v3 pipeline)"
if [[ "$v3_pipeline" !=  *'federation_extension'* ]] ; then
    new_v3_pipeline=`echo $v3_pipeline | sed -e 's/service_v3/federation_extension service_v3/g'`
    crudini --set /etc/keystone/keystone-paste.ini pipeline:api_v3 pipeline "$new_v3_pipeline"
fi



# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up database"
################################################################################
/opt/harbor/keystone/config-database.sh
/opt/harbor/keystone/create-db.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing TOKENS"
################################################################################
crudini --set $cfg token provider "fernet"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone








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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: APACHE"
################################################################################
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/conf.d/*
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/conf/*
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/saml2/ecp/metadata-config.py




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: IPSILON"
################################################################################

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying IPSILON is running"
################################################################################
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Bootstrapping keystone"
################################################################################
/opt/harbor/keystone/bootstrap-keystone.sh

tail -f /dev/null


















          #openstack identity provider create --remote-id SSSD   sssd


















################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: APACHE"
################################################################################
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/conf.d/*
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/conf/*












curl -L https://ipsilon.port.direct/idp/saml2/metadata > /etc/httpd/saml2/idp-metadata.xml

chown -R apache:apache /etc/httpd/saml2
chmod -R u=rwx,g=rx,o= /etc/httpd/saml2





























################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db



# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/keystone/config-database.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Database"
################################################################################
/opt/harbor/keystone/create-db.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing TOKENS"
################################################################################
crudini --set $cfg token provider "fernet"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Applying V3 specific paste ini"
################################################################################
crudini --set $cfg paste_deploy config_file "/etc/keystone/keystone-paste.ini"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting keystone to use domain specific drivers"
################################################################################
crudini --set $cfg identity domain_specific_drivers_enabled true
crudini --set $cfg identity domain_configurations_from_database true




# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Halting script for debug"
# ################################################################################
# tail -f /dev/null



/opt/harbor/keystone/ipa-endpoint-manager-v2-default.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Basic Config"
################################################################################
/opt/harbor/config-keystone.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing IPA LDAP"
################################################################################
/opt/harbor/keystone/config-ipa-ldap.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing PKI"
################################################################################
/opt/harbor/keystone/keystone-pki.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Bootstrapping"
################################################################################
/opt/harbor/keystone/bootstrap-keystone.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Management Complete"
################################################################################
tail -f /dev/null
