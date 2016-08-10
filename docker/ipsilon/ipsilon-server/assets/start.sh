#!/bin/bash
source /etc/os-container.env

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' )
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Installing Ipsilon"
################################################################################
if [ -f /var/lib/ipsilon/installed ] ; then
  rm -rf /var/lib/ipsilon/idp
  mkdir -p /var/lib/ipsilon/idp/saml2
  cp /var/lib/ipsilon/idp-live/saml2/* /var/lib/ipsilon/idp/saml2/
  echo "${IPA_HOST_ADMIN_PASSWORD}" | kinit "${IPA_HOST_ADMIN_USER}"
  ipsilon-server-install \
      --hostname ipsilon.${OS_DOMAIN} \
      --ipa=yes \
      --gssapi=yes \
      --form=yes \
      --info-sssd=yes \
      --admin-user=${IPA_HOST_ADMIN_USER}
  rm -rf /etc/ipsilon
  rm -rf /var/lib/ipsilon/idp
  ln -s /var/lib/ipsilon/etc /etc/ipsilon
  ln -s /var/lib/ipsilon/idp-live /var/lib/ipsilon/idp
else
  rm -rf /etc/ipsilon
  mkdir -p /var/lib/ipsilon/etc
  ln -s /var/lib/ipsilon/etc /etc/ipsilon
  echo "${IPA_HOST_ADMIN_PASSWORD}" | kinit "${IPA_HOST_ADMIN_USER}"
  ipsilon-server-install \
      --hostname ipsilon.${OS_DOMAIN} \
      --ipa=yes \
      --gssapi=yes \
      --form=yes \
      --info-sssd=yes \
      --admin-user=${IPA_HOST_ADMIN_USER} \
      --admin-dburi=postgres://${IPSILON_ADMIN_DB_USER}:${IPSILON_ADMIN_DB_PASSWORD}@ipsilon-db.${OS_DOMAIN}/${IPSILON_ADMIN_DB_NAME} \
      --users-dburi=postgres://${IPSILON_USERS_DB_USER}:${IPSILON_USERS_DB_PASSWORD}@ipsilon-db.${OS_DOMAIN}/${IPSILON_USERS_DB_NAME} \
      --transaction-dburi=postgres://${IPSILON_TRANS_DB_USER}:${IPSILON_TRANS_DB_PASSWORD}@ipsilon-db.${OS_DOMAIN}/${IPSILON_TRANS_DB_NAME} \
      --samlsessions-dburi=postgres://${IPSILON_SAMLSESSION_DB_USER}:${IPSILON_SAMLSESSION_DB_PASSWORD}@ipsilon-db.${OS_DOMAIN}/${IPSILON_SAMLSESSION_DB_NAME} \
      --saml2-session-dburl=postgres://${IPSILON_SAML2SESSION_DB_USER}:${IPSILON_SAML2SESSION_DB_PASSWORD}@ipsilon-db.${OS_DOMAIN}/${IPSILON_SAML2SESSION_DB_NAME}
  mv /var/lib/ipsilon/idp /var/lib/ipsilon/idp-live
  ln -s /var/lib/ipsilon/idp-live /var/lib/ipsilon/idp
  touch /var/lib/ipsilon/installed
fi



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Apache Config"
################################################################################
sed -i 's/Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf
sed -i 's/Listen 443 https/Listen 4143 https/' /etc/httpd/conf.d/ssl.conf
sed -i 's/_default_:443/_default_:4143/' /etc/httpd/conf.d/ssl.conf
sed -i "s/^#ServerName www.example.com:443/ServerName ${HOST}:443/" /etc/httpd/conf.d/ssl.conf
sed -i 's,^SSLCertificateFile /etc/pki/tls/certs/localhost.crt,SSLCertificateFile /etc/pki/tls/certs/ca.crt,' /etc/httpd/conf.d/ssl.conf
sed -i 's,^SSLCertificateKeyFile /etc/pki/tls/private/localhost.key,SSLCertificateKeyFile /etc/pki/tls/private/ca.key,' /etc/httpd/conf.d/ssl.conf


sed -i 's,^ErrorLog \"logs/error_log\",ErrorLog /dev/stderr,' /etc/httpd/conf/httpd.conf
sed -i 's,CustomLog \"logs/access_log\",CustomLog /dev/stdout,' /etc/httpd/conf/httpd.conf

sed -i 's,^ErrorLog logs/ssl_error_log,ErrorLog /dev/stderr,' /etc/httpd/conf.d/ssl.conf
sed -i 's,^TransferLog logs/ssl_access_log,TransferLog /dev/stdout,' /etc/httpd/conf.d/ssl.conf
sed -i 's,^CustomLog logs/ssl_request_log,CustomLog /dev/stdout,' /etc/httpd/conf.d/ssl.conf

sed -i "s,{{ OS_DOMAIN }},${OS_DOMAIN}," /etc/httpd/conf.d/ipsilon-rewrite.conf
sed -i 's,^</VirtualHost>,Include /etc/httpd/conf.d/ipsilon-rewrite.conf\n</VirtualHost>,' /etc/httpd/conf.d/ssl.conf



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Starting Dbus"
################################################################################
systemctl start dbus
systemctl restart sssd


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec httpd -D FOREGROUND
