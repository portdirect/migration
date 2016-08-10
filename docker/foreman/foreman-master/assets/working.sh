





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating the default PXE Template"
################################################################################
hammer template dump --name "PXELinux global default" | \
 sed "s,proxy.url=https://FOREMAN_INSTANCE,proxy.url=https://foreman.$(hostname -d)," | \
 sed "s,proxy.type=foreman$,proxy.type=foreman fdi.initnet=all," | \
 sed "s,^ONTIMEOUT local,ONTIMEOUT discovery," > /tmp/pxe-default
hammer template update --name "PXELinux global default" --file /tmp/pxe-default
hammer template build-pxe-default


curl -L https://raw.githubusercontent.com/theforeman/community-templates/develop/kickstart/PXELinux.erb > /tmp/kickstart-default
hammer template update --name "Kickstart default PXELinux" --file /tmp/kickstart-default

curl -L https://raw.githubusercontent.com/theforeman/community-templates/develop/kickstart/provision_atomic.erb > /tmp/kickstart-default
hammer template update --name "Atomic Kickstart default" --file /tmp/kickstart-default

curl -L https://raw.githubusercontent.com/theforeman/community-templates/develop/kickstart/provision.erb > /tmp/kickstart-default
hammer template update --name "Kickstart default" --file /tmp/kickstart-default




hammer medium create --os-family Redhat --name HarborOS --path http://rpmostree.harboros.net:8012/repo/
hammer os create \
--architectures x86_64 \
--family Redhat \
--major 7 \
--name HarborOS \
--release-name standard \
--media "HarborOS" \
--partition-tables "Kickstart default" \
--provisioning-templates "Atomic Kickstart default, Kickstart default PXELinux"








cp /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
update-ca-trust enable
update-ca-trust





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting oauth creds from config file"
################################################################################
oauth_consumer_key=$(cat /etc/foreman/settings.yaml | grep "^:oauth_consumer_key:" | awk '{print $NF}')
oauth_consumer_secret=$(cat /etc/foreman/settings.yaml | grep "^:oauth_consumer_secret:" | awk '{print $NF}')
(
echo oauth_consumer_key=$oauth_consumer_key > /var/lib/puppet/ssl/foreman_oauth
echo oauth_consumer_secret=$oauth_consumer_secret >> /var/lib/puppet/ssl/foreman_oauth
)








oauth_consumer_key=ZQgJaGg4mhb9rpwWVo69JqSaqAXEY8rF
oauth_consumer_secret=Huorv48SogMZZakx44WJNSDsLtFJuMfp
################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env
source /var/lib/puppet/ssl/foreman_oauth

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
fi


BRIDGE_DEVICE=$(hostname -s | awk -F 'foreman-proxy-' '{ print $NF }')
BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
IP_START=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".1.0"}')
IP_END=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".255.0"}')
GATEWAY_IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".0.1"}')

REVERSE_ZONE=$(echo ${GATEWAY_IP} | awk -F. '{print $3"." $2"."$1".in-addr.arpa"}')


foreman-installer \
  --no-enable-foreman \
  --no-enable-foreman-cli \
  --no-enable-foreman-plugin-bootdisk \
  --no-enable-foreman-plugin-setup \
  --no-enable-puppet \
  --enable-foreman-proxy \
  --foreman-proxy-puppetrun=false \
  --foreman-proxy-puppetca=false \
  --foreman-proxy-foreman-base-url=https://foreman.$(hostname -d) \
  --foreman-proxy-trusted-hosts=foreman.$(hostname -d) \
  --foreman-proxy-dhcp=true \
  --foreman-proxy-dhcp-interface=${BRIDGE_DEVICE} \
  --foreman-proxy-dhcp-range="${IP_START} ${IP_END}" \
  --foreman-proxy-tftp=false \
  --foreman-proxy-dns=false \
  --foreman-proxy-foreman-base-url=https://foreman.$(hostname -d) \
  --foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
  --foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret



hammer \
--debug \
-s https://foreman.$(hostname -d) \
-u $IPA_HOST_ADMIN_USER \
-p uQYPBB4SPk5px9Dr \
os list

admin / uQYPBB4SPk5px9Dr

    -p "$IPA_HOST_ADMIN_USER" \
    -w "$IPA_HOST_ADMIN_PASSWORD" \



cp /var/lib/puppet/ssl/ca/ca_crt.pem /etc/pki/ca-trust/source/anchors/ca_crt.pem
update-ca-trust enable
update-ca-trust









    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up discovery"
    ################################################################################
    foreman-installer \
        --enable-foreman-plugin-discovery \
        --foreman-proxy-plugin-discovery-install-images


: ${IPA_PORTAL_USER:="portal"}

IPA_SERVER=$(cat /etc/ipa/default.conf | grep "server" | awk '{print $3}')
IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
IPA_BASE_DN=$( cat /etc/openldap/ldap.conf | grep "^BASE " | awk '{print $2}' )
IPA_URI=$( cat /etc/openldap/ldap.conf | grep "^URI " | awk '{print $2}' )




# Add a service for Foreman
echo $IPA_PASSWORD | kinit admin
ipa service-add HTTP/$(hostname -f)@PORT.DIRECT
kdestroy








################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: kinit as the admin user"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit ${IPA_USER_ADMIN_USER}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Retriving Keytab"
################################################################################
ipa-getkeytab -s ${IPA_SERVER} -p foreman-proxy@${IPA_REALM} -k /etc/foreman-proxy/freeipa.keytab


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ending our admin session"
################################################################################
kdestroy



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Our keytab works"
################################################################################
kinit -kt /etc/foreman-proxy/freeipa.keytab foreman-proxy@PORT.DIRECT
klist



ipa hostgroup-add harboros
ipa automember-add --type=hostgroup harboros
ipa automember-add-condition --key=userclass --type=hostgroup --inclusive-regex=^harboros harboros



























/usr/sbin/foreman-installer \
--enable-foreman-plugin-cockpit \
--foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
--foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret


sleep 30s
sleep 30s


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up discovery"
################################################################################
foreman-installer \
    --enable-foreman-plugin-discovery \
    --foreman-plugin-discovery-install-images=true \
    --foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
    --foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret

hammer template dump --name "PXELinux global default" | \
 sed "s,proxy.url=https://FOREMAN_INSTANCE,proxy.url=https://foreman.$(hostname -d)," > /tmp/pxe-default
hammer template update --name "PXELinux global default" --file /tmp/pxe-default

hammer template dump --name "PXELinux global default" | \
 sed "s,proxy.type=foreman$,proxy.type=foreman fdi.initnet=all," > /tmp/pxe-default
hammer template update --name "PXELinux global default" --file /tmp/pxe-default

hammer template dump --name "PXELinux global default" | \
 sed "s,^ONTIMEOUT local,ONTIMEOUT discovery," > /tmp/pxe-default
hammer template update --name "PXELinux global default" --file /tmp/pxe-default


hammer template build-pxe-default
















hammer proxy list

hammer subnet create \
--boot-mode DHCP \
--dhcp-id 2 \
--dns-primary 10.140.0.1 \
--domains port.direct \
--from 10.140.1.0 \
--to 10.140.255.255 \
--ipam DHCP \
--mask 255.255.0.0 \
--network 10.140.0.0 \
--tftp-id 1 \
--name management



hammer subnet create \
--boot-mode DHCP \
--dhcp-id 3 \
--dns-primary 10.142.0.1 \
--domains port.direct \
--from 10.142.1.0 \
--to 10.142.255.255 \
--ipam DHCP \
--mask 255.255.0.0 \
--network 10.142.0.0 \
--name neutron

hammer subnet create \
--boot-mode DHCP \
--dhcp-id 4 \
--dns-primary 10.144.0.1 \
--domains port.direct \
--from 10.144.1.0 \
--to 10.144.255.255 \
--ipam DHCP \
--mask 255.255.0.0 \
--network 10.144.0.0 \
--name storage





harbor-host/7/x86_64/standard


hammer template dump --name "Kickstart default" | \
 sed "s,^network --bootproto,#network --bootproto," | \
 > /tmp/pxe-default

 n=0
 hammer template dump --name "Kickstart default" | \
  sed "s,network --bootproto,#network --bootproto," | while read line; do
   if [[ "$line" =~ 'network' && $n = 0 ]]; then
     echo '<% @host.interfaces.each do |interface| %>'
     echo '<% if interface.identifier != "" %>'
     echo 'network --bootproto=dhcp --device=<%= interface.identifier %> --onboot=yes'
     echo '<% end %>'
     echo '<% end %>'
     n=1
   fi
   echo "$line"
 done > /tmp/kickstart-default
hammer template update --name "Kickstart default" --file /tmp/kickstart-default






hammer os create \
--architectures x86_64 \
--family Redhat \
--major 23 \
--name fedora-atomic \
--release-name fedora-atomic \
--media "Fedora Atomic mirror" \
--partition-tables "Kickstart default" \
--provisioning-templates "Atomic Kickstart default"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Realm Joining"
################################################################################
foreman-installer \
--enable-foreman-proxy \
--foreman-proxy-realm=true \
--foreman-proxy-realm-keytab="/etc/foreman-proxy/freeipa.keytab" \
--foreman-proxy-realm-listen-on="https" \
--foreman-proxy-realm-principal="realm-proxy@${IPA_REALM}" \
--foreman-proxy-realm-provider "freeipa" \
--foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
--foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Primary Network"
################################################################################
foreman-installer \
  --enable-foreman-proxy \
  --foreman-proxy-tftp=true \
  --foreman-proxy-tftp-servername=10.140.0.10 \
  --foreman-proxy-dhcp=true \
  --foreman-proxy-dhcp-interface=br0 \
  --foreman-proxy-dhcp-gateway=10.140.0.1 \
  --foreman-proxy-dhcp-range="10.140.1.0 10.140.255.0" \
  --foreman-proxy-dhcp-nameservers="10.140.0.1" \
  --foreman-proxy-dns=true \
  --foreman-proxy-dns-interface=br0 \
  --foreman-proxy-dns-zone=port.direct \
  --foreman-proxy-dns-reverse=140.10.in-addr.arpa \
  --foreman-proxy-dns-forwarders=10.140.0.1 \
  --foreman-proxy-foreman-base-url=https://foreman.port.direct \
  --foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
  --foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret


cat >> /etc/dhcp/dhcpd.conf <<EOF
#################################
# port.direct
#################################
subnet 10.142.0.0 netmask 255.255.0.0 {
  pool
  {
    range 10.142.1.0 10.142.255.0;
  }

  option subnet-mask 255.255.0.0;
}
EOF


cat >> /etc/dhcp/dhcpd.conf <<EOF
#################################
# port.direct
#################################
subnet 10.144.0.0 netmask 255.255.0.0 {
  pool
  {
    range 10.144.1.0 10.144.255.0;
  }

  option subnet-mask 255.255.0.0;
}
EOF



systemctl restart dhcpd


hammer subnet create \
--boot-mode DHCP \
--dhcp-id $(hammer proxy list | grep $(hostname -f) | awk '{ print $1 }') \
--domain-ids $(hammer domain list | grep $(hostname -d) | awk '{ print $1 }') \
--mask 255.255.0.0 \
--network 10.142.0.0 \
--from 10.142.1.0 \
--to 10.142.255.0 \
--name neutron


hammer subnet create \
--boot-mode DHCP \
--dhcp-id $(hammer proxy list | grep $(hostname -f) | awk '{ print $1 }') \
--domain-ids $(hammer domain list | grep $(hostname -d) | awk '{ print $1 }') \
--mask 255.255.0.0 \
--network 10.144.0.0 \
--from 10.144.1.0 \
--to 10.144.255.0 \
--name storage






  foreman-installer \
    --enable-foreman-proxy \
    --foreman-proxy-tftp=true \
    --foreman-proxy-tftp-servername=10.140.0.10 \
    --foreman-proxy-dhcp=true \
    --foreman-proxy-dhcp-interface=br0 \
    --foreman-proxy-dhcp-gateway=10.140.0.1 \
    --foreman-proxy-dhcp-range="10.140.1.1 10.140.255.255" \
    --foreman-proxy-dhcp-nameservers="10.140.0.2" \
    --foreman-proxy-dns=true \
    --foreman-proxy-dns-interface=br0 \
    --foreman-proxy-dns-zone=port.direct \
    --foreman-proxy-dns-reverse=140.10.in-addr.arpa \
    --foreman-proxy-dns-forwarders=10.140.0.1 \
    --foreman-proxy-foreman-base-url=https://foreman.port.direct \
    --foreman-proxy-oauth-consumer-key=t9fyfX53bkhEWEKuiGkb54MM3DZvFNqs \
    --foreman-proxy-oauth-consumer-secret=nHDgUEmUkBJsj2g6gy2dXbyoBpfmZ5Kr
    FvnoxgCj2ZSDtASVpTMAC2ENYL7Q6dcP	OAuth consumer key
    OAuth consumer secret	spPcFHKTDbefrYotzi7GVyPRhgrimQNB
su -s /bin/sh -c "foreman-rake templates:sync" foreman
su -s /bin/sh -c "foreman-rake db:migrate" foreman
su -s /bin/sh -c "foreman-rake db:seed" foreman
