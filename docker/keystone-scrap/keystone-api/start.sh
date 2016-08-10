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



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up database"
################################################################################
/opt/harbor/keystone/config-database.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing TOKENS"
################################################################################
crudini --set $cfg token provider "fernet"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /var/log/keystone





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt









################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: IPSILON"
################################################################################

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying IPSILON is running"
################################################################################
while ! curl -o /dev/null -s --fail https://ipsilon.${OS_DOMAIN}/idp/login/form; do
    echo "${OS_DISTRO}: Waiting for IPSILON @ https://ipsilon.${OS_DOMAIN}/idp/login/form"
    sleep 1;
done



SP_CONF=websso
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up Ipsilon ${SP_CONF}"
################################################################################
mkdir -p /etc/httpd/saml2/${SP_CONF}
cat /etc/os-${SP_CONF}/key | sed 's/\\n/\n/g' > /etc/httpd/saml2/${SP_CONF}/certificate.key
cat /etc/os-${SP_CONF}/pem | sed 's/\\n/\n/g' > /etc/httpd/saml2/${SP_CONF}/certificate.pem
cat /etc/os-${SP_CONF}/metadata | sed 's/\\n/\n/g' > /etc/httpd/saml2/${SP_CONF}/metadata.xml
curl -L https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata > /etc/httpd/saml2/websso/idp-metadata.xml



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: APACHE"
################################################################################
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/conf.d/*
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/conf/*
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${KEYSTONE_PUBLIC_SERVICE_HOST}/" /etc/httpd/saml2/ecp/metadata-config.py


tail -f /dev/null

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
exec httpd -D FOREGROUND

















docker/keystone/keystone-base/assets/etc








################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Applying V3 specific paste ini"
################################################################################
crudini --set $cfg paste_deploy config_file "/etc/keystone/keystone-paste.ini"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting keystone to use domain specific drivers"
################################################################################
crudini --set $cfg identity domain_specific_drivers_enabled "true"
crudini --set $cfg identity domain_configurations_from_database "true"


















export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Default Domain ID from ETCD"
################################################################################
IPA_DOMAIN_ID=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/default_domain_id)
check_required_vars IPA_DOMAIN_ID

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring to make the ${IPA_DOMAIN_ID} the default for v2 requests"
################################################################################
crudini --set $cfg identity default_domain_id "${IPA_DOMAIN_ID}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Basic Config"
################################################################################
/opt/harbor/config-keystone.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing PKI"
################################################################################
/opt/harbor/keystone/keystone-pki.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
exec httpd -D FOREGROUND
