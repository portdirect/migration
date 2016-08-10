#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT="EMAIL"

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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SSMTP"
################################################################################
ssmtp_cfg=/etc/ssmtp/ssmtp.conf

cat > $ssmtp_cfg <<EOF
root=${PORTAL_DEFAULT_ADMIN_EMAIL}
mailhub=${PORTAL_SMTP_HOST}:${PORTAL_SMTP_PORT}
rewriteDomain=gmail.com
hostname=$(hostname -f)
UseTLS=Yes
UseSTARTTLS=Yes
AuthUser=${PORTAL_SMTP_USER}
AuthPass=${PORTAL_SMTP_PASS}
FromLineOverride=yes
TLS_CA_File=/etc/pki/tls/certs/ca-bundle.crt
EOF
ssmtp_aliases=/etc/ssmtp/revaliases
echo "root:${PORTAL_DEFAULT_FROM_EMAIL}:${PORTAL_SMTP_HOST}:${PORTAL_SMTP_PORT}" >> $ssmtp_aliases
