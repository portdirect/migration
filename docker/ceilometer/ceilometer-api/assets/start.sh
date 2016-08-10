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
. /opt/harbor/config-ceilometer.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' | sed 's/\\r$//g'  > /etc/pki/tls/certs/ca.crt
cat /etc/os-ssl/ca | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/certs/ca-auth.crt


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec httpd -D FOREGROUND
#exec /usr/bin/ceilometer-api --debug --config-file /etc/ceilometer/ceilometer.conf
