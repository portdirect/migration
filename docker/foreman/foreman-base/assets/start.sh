#!/bin/bash
set -e
################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: Setting Up IPA"
################################################################################
if [ -f /etc/ipa/ca.crt ] ; then
  echo "IPA is installed in this container"
else
  /usr/sbin/ipa-client-install \
      -p "$IPA_HOST_ADMIN_USER" \
      -w "$IPA_HOST_ADMIN_PASSWORD" \
      --all-ip-addresses \
      --no-ntp \
      -U \
      --enable-dns-updates \
      --force-join
  cp /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
  update-ca-trust
fi
update-ca-trust enable
systemctl enable certmonger
systemctl start certmonger


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting A Certifiacte for the puppet client and smart proxy communication"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit "$IPA_USER_ADMIN_USER"
ipa service-show puppet/$(hostname -f) || ipa service-add puppet/$(hostname -f)
mkdir -p $(dirname $(puppet agent --configprint hostcert))
mkdir -p $(dirname $(puppet agent --configprint hostprivkey))
mkdir -p $(dirname $(puppet agent --configprint localcacert))
cat /etc/ipa/ca.crt >  $(puppet agent --configprint localcacert)
ls $(puppet agent --configprint hostprivkey) || ipa-getcert request -r \
  -f $(puppet agent --configprint hostcert) \
  -k $(puppet agent --configprint hostprivkey) \
  -N CN=$(hostname -f) \
  -D $(hostname -f) \
  -K puppetmaster/$(hostname -f)
kdestroy -A


################################################################################
echo "${OS_DISTRO}: Waiting for our keys"
################################################################################
echo "waiting for hostcert"
while [ ! -f $(puppet agent --configprint hostcert) ]; do sleep 2; done
echo "waiting for hostprivkey"
while [ ! -f $(puppet agent --configprint hostprivkey) ]; do sleep 2; done
echo "waiting for localcacert"
while [ ! -f $(puppet agent --configprint localcacert) ]; do sleep 2; done


################################################################################
echo "${OS_DISTRO}: Fixing Permissions"
################################################################################
chown -R puppet:puppet /var/lib/puppet
chown -R puppet:puppet $(dirname $(puppet agent --configprint hostcert))
chown -R puppet:puppet $(dirname $(puppet agent --configprint hostprivkey))
chown -R puppet:puppet $(dirname $(puppet agent --configprint localcacert))
chmod 0644 $(puppet agent --configprint hostcert)
chmod 0640 $(puppet agent --configprint hostprivkey)


################################################################################
echo "${OS_DISTRO}: Fixing Permissions"
################################################################################
# crudini doesn't like puppets leading whitespace
sed -i -e 's/^[ \t]*//' /etc/puppet/puppet.conf
crudini --set /etc/puppet/puppet.conf agent certificate_revocation "false"
crudini --set /etc/puppet/puppet.conf agent certname "$(hostname -f)"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting A Certifiacte for the Forman Web UI"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit "$IPA_USER_ADMIN_USER"
ipa service-show HTTP/$(hostname -f) || ipa service-add HTTP/$(hostname -f)
mkdir -p /var/lib/apache/ssl/certs
mkdir -p /var/lib/apache/ssl/private_keys
ls /var/lib/apache/ssl/private_keys/$(hostname -f).pem || ipa-getcert request -r \
  -f /var/lib/apache/ssl/certs/$(hostname -f).pem \
  -k /var/lib/apache/ssl/private_keys/$(hostname -f).pem \
  -N CN=$(hostname -f) \
  -D $(hostname -f) \
  -K HTTP/$(hostname -f)
kdestroy -A
################################################################################
echo "${OS_DISTRO}: Waiting for our keys"
################################################################################
echo "waiting for hostcert"
while [ ! -f /var/lib/apache/ssl/certs/$(hostname -f).pem ]; do sleep 2; done
echo "waiting for hostprivkey"
while [ ! -f /var/lib/apache/ssl/private_keys/$(hostname -f).pem ]; do sleep 2; done


tail -f /dev/null
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Installing Foreman"
################################################################################
/usr/sbin/foreman-installer \
--foreman-ipa-authentication=true \
--no-enable-foreman-proxy \
--no-enable-puppet \
--foreman-db-type=mysql \
--foreman-proxy-tftp=false \
--foreman-server-ssl-cert=/var/lib/apache/ssl/certs/$(hostname -f).pem \
--foreman-server-ssl-key=/var/lib/apache/ssl/private_keys/$(hostname -f).pem


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting oauth creds from config file"
################################################################################
oauth_consumer_key=$(cat /etc/foreman/settings.yaml | grep "^:oauth_consumer_key:" | awk '{print $NF}')
oauth_consumer_secret=$(cat /etc/foreman/settings.yaml | grep "^:oauth_consumer_secret:" | awk '{print $NF}')
(
echo oauth_consumer_key=$oauth_consumer_key > /var/lib/pod/foreman_oauth
echo oauth_consumer_secret=$oauth_consumer_secret >> /var/lib/pod/foreman_oauth
)

#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Running Puppet Agent to pupulate host info"
# ################################################################################
# puppet agent -t || puppet agent -t
#
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating cirts for proxys"
# ################################################################################
# for BRIDGE_DEVICE in master br0 br1 br2; do
#   (puppet cert list --all | grep -q foreman-proxy-${BRIDGE_DEVICE}.$(hostname -d) ) || puppet cert --generate foreman-proxy-${BRIDGE_DEVICE}.$(hostname -d)
# done
#
#
#
#
#
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up discovery"
# ################################################################################
# foreman-installer \
#   --enable-foreman-plugin-discovery \
#   --foreman-plugin-discovery-install-images=false \
#   --foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
#   --foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret
# cat /var/lib/puppet/ssl/certs/ca.pem > /etc/pki/ca-trust/source/anchors/puppet.pem
# update-ca-trust enable
# update-ca-trust
#
#
#
#
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Realm Joining"
# ################################################################################
# mkdir -p /etc/foreman-proxy
# cd /etc/foreman-proxy && \
#     echo ${IPA_HOST_ADMIN_PASSWORD} | foreman-prepare-realm ${IPA_HOST_ADMIN_USER} realm-proxy
# chown foreman-proxy /etc/foreman-proxy/freeipa.keytab
# chmod 600 /etc/foreman-proxy/freeipa.keytab
#
#
# IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
# foreman-installer \
# --enable-foreman-proxy \
# --foreman-proxy-tftp=false \
# --foreman-proxy-realm=true \
# --foreman-proxy-realm-keytab="/etc/foreman-proxy/freeipa.keytab" \
# --foreman-proxy-realm-listen-on="https" \
# --foreman-proxy-realm-principal="realm-proxy@${IPA_REALM}" \
# --foreman-proxy-realm-provider "freeipa" \
# --foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
# --foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret
