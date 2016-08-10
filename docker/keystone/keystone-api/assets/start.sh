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



# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: CONFIG"
################################################################################
crudini --set $cfg DEFAULT debug "True"
/opt/harbor/config-keystone.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_HOST
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt
sed -i "s/{{ KEYSTONE_PUBLIC_SERVICE_HOST }}/${HOST}/" /etc/httpd/conf.d/wsgi-keystone.conf
sed -i "s/{{ KEYSTONE_ADMIN_SERVICE_HOST }}/${HOST}/" /etc/httpd/conf.d/wsgi-keystone.conf


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: IPSILON"
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying IPSILON is running"
while ! curl -o /dev/null -s --fail https://ipsilon.${OS_DOMAIN}/idp/login/form; do
    echo "${OS_DISTRO}: Waiting for IPSILON @ https://ipsilon.${OS_DOMAIN}/idp/login/form"
    sleep 1;
done

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up Ipsilon"
################################################################################
mkdir -p /etc/httpd/mellon
cat /etc/os-websso/key | sed 's/\\n/\n/g' > /etc/httpd/mellon/https_keystone.port.direct_keystone.key
cat /etc/os-websso/pem | sed 's/\\n/\n/g' > /etc/httpd/mellon/https_keystone.port.direct_keystone.cert
cat /etc/os-websso/metadata | sed 's/\\n/\n/g' > /etc/httpd/mellon/https_keystone.port.direct_keystone.xml
curl -L https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata > /etc/httpd/mellon/idp-metadata.xml
sed -i "s/{{OS_DOMAIN}}/${OS_DOMAIN}/" /etc/keystone/sso_callback_template.html

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
touch /var/log/keystone/keystone.log
chown keystone:keystone /var/log/keystone/keystone.log
tail -f /var/log/keystone/keystone.log &
exec httpd -D FOREGROUND
