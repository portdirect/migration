#!/bin/sh
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
. /opt/harbor/harbor-common.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' | sed 's/\\r$//g'  > /etc/pki/tls/certs/ca.crt
cat /etc/os-ssl/ca | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/certs/ca-auth.crt


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
mkdir -p /etc/httpd/saml2/mellon
cat /etc/os-websso/key | sed 's/\\n/\n/g' > /etc/httpd/saml2/mellon/certificate.key
cat /etc/os-websso/pem | sed 's/\\n/\n/g' > /etc/httpd/saml2/mellon/certificate.pem
cat /etc/os-websso/metadata | sed 's/\\n/\n/g' > /etc/httpd/saml2/mellon/metadata.xml
curl -L https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata > /etc/httpd/saml2/mellon/idp-metadata.xml
chown -R apache:apache /etc/httpd/saml2/mellon

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Apache"
################################################################################
sed -i "s/{{ GRAFANA_API_HOST }}/grafana.${OS_DOMAIN}/" /etc/httpd/conf.d/grafana.conf


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LAUNCHING APACHE"
################################################################################
exec httpd -D FOREGROUND
