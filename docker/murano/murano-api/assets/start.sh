#!/bin/sh
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
. /opt/harbor/config-murano.sh


export cfg=/etc/murano/murano.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
TLS_HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' | sed 's/\\r$//' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' | sed 's/\\r$//' > /etc/pki/tls/certs/ca.crt
cat /etc/os-ssl/ca | sed 's/\\n/\n/g' | sed 's/\\r$//' > /etc/pki/tls/certs/ca-auth.crt
crudini --set $cfg ssl cert_file "/etc/pki/tls/certs/ca.crt"
crudini --set $cfg ssl key_file "/etc/pki/tls/private/ca.key"
#crudini --set $cfg ssl ca_file "/etc/pki/tls/certs/ca-auth.crt"
crudini --set $cfg ssl version "TLSv1_2"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Adding local CA to CA-bundle for python-requests"
################################################################################
cat /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem >> /usr/lib/python2.7/site-packages/requests/cacert.pem


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Memcached for Keystone Middleware"
################################################################################
SECRET_KEY_LENGTH=16
SECRET_KEY=$(openssl rand -hex $SECRET_KEY_LENGTH | base64 --wrap 0 | fold -w $SECRET_KEY_LENGTH | sed -n 2p)
crudini --set $cfg keystone_authtoken memcached_servers "127.0.0.1:11211"
crudini --set $cfg keystone_authtoken memcache_security_strategy "ENCRYPT"
crudini --set $cfg keystone_authtoken memcache_secret_key "${SECRET_KEY}"
crudini --set $cfg keystone_authtoken memcache_secret_key "${SECRET_KEY}"
#crudini --set $cfg keystone_authtoken domain_name "Default"





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/sh -c "exec /usr/bin/murano-api --config-file /etc/murano/murano.conf --debug" murano
