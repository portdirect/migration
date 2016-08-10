#!/bin/bash
set -e
OS_DISTRO=HarborOS
OPENSTACK_COMPONENT=Foreman
OPENSTACK_SUBCOMPONENT=Server
################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env

################################################################################
echo "${OS_DISTRO}: Running System Update"
################################################################################
yum update -y
yum upgrade -y

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
systemctl enable sssd
systemctl restart sssd



################################################################################
echo "${OS_DISTRO}: Setting up puppet agent"
################################################################################
# crudini doesn't like puppets leading whitespace
sed -i -e 's/^[ \t]*//' /etc/puppet/puppet.conf
crudini --set /etc/puppet/puppet.conf main server "puppet-master.$(hostname -d)"
puppet agent --test || (
    mkdir -p /root/.ssh
    cat /var/pod/auth/puppetmaster/id_rsa > /root/.ssh/id_rsa
    chmod 0600 /root/.ssh/id_rsa
    ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa root@puppet-master.$(hostname -d) puppet cert clean $(hostname -f)
    rm -f /root/.ssh/id_rsa
    find /var/lib/puppet/ssl -name $(hostname -f).pem -delete
    puppet agent --test || true )


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting A Certifiacte for the Forman Proxy"
################################################################################
echo "${IPA_USER_ADMIN_PASSWORD}" | kinit "$IPA_USER_ADMIN_USER"
ipa service-show HTTP/$(hostname -f) || ipa service-add HTTP/$(hostname -f)
mkdir -p /etc/forman/certs

export FOREMAN_UI_CERT=/etc/forman/certs/$(hostname -f).crt
export FOREMAN_UI_KEY=/etc/forman/certs/$(hostname -f).key
export FOREMAN_UI_CA=/etc/forman/certs/$(hostname -f).ca

cat /etc/ipa/ca.crt > ${FOREMAN_UI_CA}
ls ${FOREMAN_UI_KEY} || ipa-getcert request -r \
  -f ${FOREMAN_UI_CERT} \
  -k ${FOREMAN_UI_KEY} \
  -N CN=$(hostname -f) \
  -D $(hostname -f) \
  -K puppetmaster/$(hostname -f)
kdestroy -A


################################################################################
echo "${OS_DISTRO}: Waiting for our keys"
################################################################################
echo "waiting for hostcert"
while [ ! -f ${FOREMAN_UI_CERT} ]; do sleep 2; done
echo "waiting for hostprivkey"
while [ ! -f ${FOREMAN_UI_KEY} ]; do sleep 2; done
echo "waiting for localcacert"
while [ ! -f ${FOREMAN_UI_CA} ]; do sleep 2; done


################################################################################
echo "${OS_DISTRO}: Fixing Permissions"
################################################################################
chown -R apache:apache /etc/forman/certs
chown -R apache:apache ${FOREMAN_UI_CERT}
chown -R apache:apache ${FOREMAN_UI_KEY}
chown -R apache:apache ${FOREMAN_UI_CA}
chmod 0644 ${FOREMAN_UI_CERT}
chmod 0640 ${FOREMAN_UI_KEY}


################################################################################
echo "${OS_DISTRO}: Starting Foreman installer"
################################################################################
/usr/sbin/foreman-installer \
--foreman-ipa-authentication=true \
--no-enable-foreman-proxy \
--no-enable-puppet \
--foreman-locations-enabled=true \
--foreman-organizations-enabled=true \
--foreman-initial-location="HarborOS" \
--foreman-initial-organization="HarborOS" \
--enable-foreman-plugin-discovery \
--enable-foreman-plugin-docker \
--enable-foreman-plugin-bootdisk \
--enable-foreman-plugin-tasks \
--enable-foreman-compute-ec2 \
--enable-foreman-compute-gce \
--enable-foreman-compute-libvirt \
--enable-foreman-compute-openstack \
--enable-foreman-compute-ovirt \
--enable-foreman-compute-rackspace \
--enable-foreman-compute-vmware \
--foreman-db-type=mysql \
--foreman-db-database=${FOREMAN_DB_NAME} \
--foreman-db-username=${FOREMAN_DB_USER} \
--foreman-db-password=${FOREMAN_DB_PASSWORD} \
--foreman-db-host=database.$(hostname -d) \
--foreman-db-manage=false \
--foreman-email-delivery-method=smtp \
--foreman-email-smtp-address=${FOREMAN_SMTP_HOST} \
--foreman-email-smtp-authentication=login \
--foreman-email-smtp-password="${FOREMAN_SMTP_PASS}" \
--foreman-email-smtp-port=${FOREMAN_SMTP_PORT} \
--foreman-email-smtp-user-name="${FOREMAN_SMTP_USER}" \
--foreman-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
--foreman-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}" \
--foreman-proxy-puppet-url="https://puppet-master.$(hostname -d):8140" \
--foreman-server-ssl-cert="${FOREMAN_UI_CERT}" \
--foreman-server-ssl-chain="${FOREMAN_UI_CA}" \
--foreman-server-ssl-key="${FOREMAN_UI_KEY}" \
--foreman-websockets-ssl-cert="${FOREMAN_UI_CERT}" \
--foreman-websockets-ssl-key="${FOREMAN_UI_KEY}"


sed -i "s/Foreman/$(hostname -d)/" /usr/share/foreman/app/views/home/_topbar.html.erb


################################################################################
echo "${OS_DISTRO}: Setting Up the Database"
################################################################################
su -s /bin/sh -c "/usr/share/foreman/extras/dbmigrate" foreman
su -s /bin/sh -c "foreman-rake db:seed" foreman


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Running api rake task"
################################################################################
su -s /bin/sh -c "foreman-rake apipie:cache" foreman

systemctl restart httpd


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Realm Smart Proxy"
################################################################################
export IPA_SERVER=$(cat /etc/ipa/default.conf | grep "^server" | awk '{print $3}')
export IPA_REALM=$(cat /etc/ipa/default.conf | grep "^realm" | awk '{print $3}')
export IPA_BASE_DN=$( cat /etc/openldap/ldap.conf | grep "^BASE " | awk '{print $2}' )
export IPA_URI=$( cat /etc/openldap/ldap.conf | grep "^URI " | awk '{print $2}' )

mkdir -p /etc/foreman-proxy
cd /etc/foreman-proxy && \
    echo ${IPA_HOST_ADMIN_PASSWORD} | foreman-prepare-realm ${IPA_HOST_ADMIN_USER} realm-proxy
chown foreman-proxy /etc/foreman-proxy/freeipa.keytab
chmod 600 /etc/foreman-proxy/freeipa.keytab

foreman-installer \
--enable-foreman-proxy \
--foreman-proxy-puppetca=false \
--foreman-proxy-puppetrun=false \
--foreman-proxy-realm=true \
--foreman-proxy-tftp=false \
--foreman-proxy-realm-keytab="/etc/foreman-proxy/freeipa.keytab" \
--foreman-proxy-realm-listen-on="https" \
--foreman-proxy-realm-principal="realm-proxy@${IPA_REALM}" \
--foreman-proxy-realm-provider "freeipa" \
--foreman-proxy-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
--foreman-proxy-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}"

################################################################################
echo "${OS_DISTRO}: Setting Up the Database"
################################################################################
su -s /bin/sh -c "/usr/share/foreman/extras/dbmigrate" foreman
su -s /bin/sh -c "foreman-rake db:seed" foreman

systemctl restart httpd


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Remote Exec Smart Proxy"
################################################################################
yum install -y /opt/tfm-packages/*.rpm

foreman-installer \
--enable-foreman-proxy \
--foreman-proxy-puppetca=false \
--foreman-proxy-puppetrun=false \
--foreman-proxy-realm=true \
--foreman-proxy-tftp=false \
--enable-foreman-plugin-remote-execution \
--enable-foreman-proxy-plugin-remote-execution-ssh \
--foreman-proxy-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
--foreman-proxy-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}"
systemctl restart httpd



################################################################################
echo "${OS_DISTRO}: Starting ha-proxy to accept external connections to the ui"
################################################################################
systemctl enable haproxy
systemctl restart haproxy


################################################################################
echo "${OS_DISTRO}: Forcing Puppet to check in and starting the puppet agent"
################################################################################
puppet agent --test || true
systemctl start puppet
systemctl enable puppet

tail -f /dev/null

# Patch hammer to support realms
HAMMER_ROOT=/opt/theforeman/tfm/root/usr/share/gems/gems/hammer_cli_foreman-0.6.2
curl -L https://raw.githubusercontent.com/stbenjam/hammer-cli-foreman/7fd864492b4ec1b544eb68f3a86b11e431cb2703/lib/hammer_cli_foreman/realm.rb > $HAMMER_ROOT/lib/hammer_cli_foreman/realm.rb
curl -L https://raw.githubusercontent.com/stbenjam/hammer-cli-foreman/7fd864492b4ec1b544eb68f3a86b11e431cb2703/lib/hammer_cli_foreman.rb > $HAMMER_ROOT/lib/hammer_cli_foreman.rb


export IPA_REALM=$(cat /etc/ipa/default.conf | grep "^realm" | awk '{print $3}')
FOREMAN_PASSWORD="$(foreman-rake permissions:reset | awk '{ print $NF }')"
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Createing the default location"
################################################################################

su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} location info --name $(hostname -d) || \
                  hammer -u admin -p ${FOREMAN_PASSWORD} location create --name $(hostname -d)"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Createing the default organization"
################################################################################
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} organization info --name $(hostname -d) || \
                  hammer -u admin -p ${FOREMAN_PASSWORD} organization create --name $(hostname -d)"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Createing the default domain"
################################################################################
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} domain info --name $(hostname -d) || \
                  hammer -u admin -p ${FOREMAN_PASSWORD} domain create --name $(hostname -d)"
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} domain update \
--name $(hostname -d) \
--locations $(hostname -d) \
--organizations $(hostname -d)" root



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Createing the default hostgroup"
################################################################################
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} hostgroup info --name $(hostname -d)" root || \
  su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} hostgroup create --name $(hostname -d)" root
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} hostgroup update \
--name $(hostname -d) \
--locations $(hostname -d) \
--organizations $(hostname -d) \
--environment production \
--domain $(hostname -d) \
--realm ${IPA_REALM} \
--puppet-proxy puppet-master.$(hostname -d) \
--puppet-ca-proxy puppet-master.$(hostname -d) \
--architecture x86_64" root

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Createing the default service hostgroup"
################################################################################
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} hostgroup info --name $(hostname -d)-service" root || \
  su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} hostgroup create --name $(hostname -d)-service" root
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} hostgroup update \
--name $(hostname -d)-service \
--locations $(hostname -d) \
--organizations $(hostname -d) \
--environment production \
--domain $(hostname -d) \
--realm ${IPA_REALM} \
--puppet-proxy puppet-master.$(hostname -d) \
--puppet-ca-proxy puppet-master.$(hostname -d) \
--architecture x86_64" root


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating Puppet Smart proxy"
################################################################################
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy import-classes --name puppet-master.$(hostname -d)" root
INITIAL_PUPPET_PROXY_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy info --name puppet-master.$(hostname -d) | head -1 | awk '{ print \$NF }'" root )
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy update \
--name puppet-master.$(hostname -d) \
--locations $(hostname -d) \
--organizations $(hostname -d)" root
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} host update \
--name puppet-master.$(hostname -d) \
--location $(hostname -d) \
--organization $(hostname -d) \
--hostgroup $(hostname -d)-service" root

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating Realm Smart proxy"
################################################################################
INITIAL_REALM_PROXY_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy info --name foreman.$(hostname -d) | head -1 | awk '{ print \$NF }'" root )
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy update \
--name foreman.$(hostname -d) \
--locations $(hostname -d) \
--organizations $(hostname -d)" root
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} host update \
--name foreman.$(hostname -d) \
--location $(hostname -d) \
--organization $(hostname -d) \
--hostgroup $(hostname -d)-service" root





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating bridge Smart proxys"
################################################################################
for BRIDGE_DEVICE in br0 br1 br2; do
  su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy update \
  --name foreman-proxy-${BRIDGE_DEVICE}.$(hostname -d) \
  --locations $(hostname -d) \
  --organizations $(hostname -d)" root
  su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} host update \
  --name foreman-proxy-${BRIDGE_DEVICE}.$(hostname -d) \
  --location $(hostname -d) \
  --organization $(hostname -d) \
  --hostgroup $(hostname -d)-service" root
done




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Createing the default realm"
################################################################################

INITIAL_REALM_PROXY_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy info --name foreman.$(hostname -d) | head -1 | awk '{ print \$NF }'" root )
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} realm info --name ${IPA_REALM}" root || \
  su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} realm create \
  --name ${IPA_REALM} \
  --realm-type 'FreeIPA' \
  --organizations $(hostname -d) \
  --locations $(hostname -d)\
  --realm-proxy-id ${INITIAL_REALM_PROXY_ID}" root



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up Subnets"
################################################################################
MANAGEMENT_SUBNET_PROXY_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy info --name foreman-proxy-br0.$(hostname -d) | head -1 | awk '{ print \$NF }'" root )
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} subnet info --name management || hammer -u admin -p ${FOREMAN_PASSWORD} subnet create \
--boot-mode DHCP \
--ipam DHCP \
--dhcp-id ${MANAGEMENT_SUBNET_PROXY_ID} \
--domains $(hostname -d) \
--tftp-id ${MANAGEMENT_SUBNET_PROXY_ID} \
--locations $(hostname -d) \
--organizations $(hostname -d) \
--network 10.140.0.0 \
--mask 255.255.0.0 \
--gateway 10.140.0.1 \
--dns-primary 10.140.0.1 \
--from 10.140.1.0 \
--to 10.140.255.0 \
--name management" root


NEUTRON_SUBNET_PROXY_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy info --name foreman-proxy-br1.$(hostname -d) | head -1 | awk '{ print \$NF }'" root )
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} subnet info --name neutron || hammer -u admin -p ${FOREMAN_PASSWORD} subnet create \
--boot-mode DHCP \
--ipam DHCP \
--dhcp-id ${NEUTRON_SUBNET_PROXY_ID} \
--domains $(hostname -d) \
--locations $(hostname -d) \
--organizations $(hostname -d) \
--network 10.142.0.0 \
--mask 255.255.0.0 \
--from 10.142.1.0 \
--to 10.142.255.0 \
--name neutron" root


STORAGE_SUBNET_PROXY_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} proxy info --name foreman-proxy-br2.$(hostname -d) | head -1 | awk '{ print \$NF }'" root )
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} subnet info --name storage || hammer -u admin -p ${FOREMAN_PASSWORD} subnet create \
--boot-mode DHCP \
--ipam DHCP \
--dhcp-id ${STORAGE_SUBNET_PROXY_ID} \
--domains $(hostname -d) \
--locations $(hostname -d) \
--organizations $(hostname -d) \
--network 10.144.0.0 \
--mask 255.255.0.0 \
--from 10.144.1.0 \
--to 10.144.255.0 \
--name storage" root




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating the default PXE Template"
################################################################################
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template dump --name \"PXELinux global default\" | \
 sed \"s,proxy.url=https://FOREMAN_INSTANCE,proxy.url=https://foreman.$(hostname -d),\" | \
 sed \"s,proxy.type=foreman$,proxy.type=foreman fdi.initnet=all,\" | \
 sed \"s,^ONTIMEOUT local,ONTIMEOUT discovery,\" > /tmp/pxe-default" root
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template update --name \"PXELinux global default\" --file /tmp/pxe-default" root
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template build-pxe-default || true" root


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating templates"
################################################################################

su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template update --name \"Atomic Kickstart default\" --type provision --file /opt/harbor/templates/Atomic-Kickstart-default.erb " root

su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template create --name \"freeipa_register_atomic\" --type snippet --file /opt/harbor/templates/freeipa_register_atomic.erb || \
hammer -u admin -p ${FOREMAN_PASSWORD} template update --name \"freeipa_register_atomic\" --type snippet --file /opt/harbor/templates/freeipa_register_atomic.erb " root

su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template create --name \"Kickstart default PXELinux\" --type PXELinux --file /opt/harbor/templates/Kickstart-default-PXELinux.erb || \
hammer -u admin -p ${FOREMAN_PASSWORD} template update --name \"Kickstart default PXELinux\" --type PXELinux --file /opt/harbor/templates/Kickstart-default-PXELinux.erb " root


su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template create --name \"kickstart_atomic_networking_setup\" --type snippet --file /opt/harbor/templates/kickstart_atomic_networking_setup.erb || \
hammer -u admin -p ${FOREMAN_PASSWORD} template update --name \"kickstart_atomic_networking_setup\" --type snippet --file /opt/harbor/templates/kickstart_atomic_networking_setup.erb " root

su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template create --name \"puppet_atomic.conf\" --type snippet --file /opt/harbor/templates/puppet_atomic.conf || \
hammer -u admin -p ${FOREMAN_PASSWORD} template update --name \"puppet_atomic.conf\" --type snippet --file /opt/harbor/templates/puppet_atomic.conf " root

su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template create --name \"puppet_setup_atomic\" --type snippet --file /opt/harbor/templates/puppet_setup_atomic.erb || \
hammer -u admin -p ${FOREMAN_PASSWORD} template update --name \"puppet_setup_atomic\" --type snippet --file /opt/harbor/templates/puppet_setup_atomic.erb " root


su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} partition-table update --name \"Kickstart default\" --file /opt/harbor/templates/Kickstart-default.partition-table.erb" root


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting OS Info from master.$(hostname -d)"
################################################################################
OS_NAME=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} host facts --name master.$(hostname -d)" root | grep "^operatingsystem " | awk '{ print $NF }')
OS_RELEASE_FULL=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} host facts --name master.$(hostname -d)" root | grep "^operatingsystemrelease " | awk '{ print $NF }')
OS_RELEASE_MAJOR=$( echo ${OS_RELEASE_FULL} | awk -F '.' '{ print $1 }')
OS_RELEASE_MINOR=$( echo ${OS_RELEASE_FULL} | awk -F '.' '{ print $2 }')
OS_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} os info --title \"${OS_NAME} ${OS_RELEASE_MAJOR}.${OS_RELEASE_MINOR}\"" root | grep '^Id: ' | awk '{ print $NF }')
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} os info --id ${OS_ID}" root


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${OS_DISTRO} repo"
################################################################################
OS_REPO_URL="http://rpmostree.harboros.net:8012/repo/"
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} medium info --name ${OS_DISTRO} || ( hammer -u admin -p ${FOREMAN_PASSWORD} medium create --name ${OS_DISTRO} --operatingsystem-ids ${OS_ID} --os-family Redhat --path \"${OS_REPO_URL}\" && hammer -u admin -p ${FOREMAN_PASSWORD} medium update --name ${OS_DISTRO} --organizations $(hostname -d) --locations $(hostname -d) )" root


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up templates for ${OS_NAME} ${OS_RELEASE_MAJOR}.${OS_RELEASE_MINOR}"
################################################################################
TEMPLATE_NAME="Atomic Kickstart default"
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} os add-config-template --id ${OS_ID} --config-template \"${TEMPLATE_NAME}\"" root
TEMPLATE_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template info --name \"${TEMPLATE_NAME}\"" root | grep '^Id: ' | awk '{ print $NF }')
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} os set-default-template --id ${OS_ID} --config-template-id ${TEMPLATE_ID}" root


TEMPLATE_NAME="Kickstart default PXELinux"
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} os add-config-template --id ${OS_ID} --config-template \"${TEMPLATE_NAME}\"" root
TEMPLATE_ID=$(su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template info --name \"${TEMPLATE_NAME}\"" root | grep '^Id: ' | awk '{ print $NF }')
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} os set-default-template --id ${OS_ID} --config-template-id ${TEMPLATE_ID}" root


PTABLE_TEMPLATE_NAME="Kickstart default"
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} os add-ptable --id ${OS_ID} --partition-table \"${PTABLE_TEMPLATE_NAME}\"" root



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating Master host"
################################################################################
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} host update \
--name master.$(hostname -d) \
--location $(hostname -d) \
--organization $(hostname -d) \
--hostgroup $(hostname -d)" root






























































































































su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template dump --name \"Atomic Kickstart default\" "

su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template dump --name \"kickstart_atomic_networking_setup\" "
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template dump --name \"puppet_atomic.conf\" "
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template dump --name \"puppet_setup_atomic\" "


su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} partition-table dump --name \"Kickstart default\" "


su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template info --name \"puppet_setup_atomic\" || hammer -u admin -p ${FOREMAN_PASSWORD} template create --name \"puppet_setup_atomic\" --type snippet --file /opt/harbor/puppet_setup_atomic.erb" root
su -s /bin/sh -c "hammer -u admin -p ${FOREMAN_PASSWORD} template info --name \"freeipa_register_atomic\" || hammer -u admin -p ${FOREMAN_PASSWORD} template create --name \"freeipa_register_atomic\" --type snippet --file /opt/harbor/freeipa_register_atomic.erb" root






hammer -u admin -p ${FOREMAN_PASSWORD} hostgroup create --architecture x86_64 --ask-root-pass no --domain $(hostname -d) --environment ${ENVIRONMENT_NAME} --operatingsystem "centos 7" --medium "CentOS mirror" --partition-table "Kickstart default"  --puppet-ca-proxy "puppet-master.$(hostname -d)" --realm PORT.DIRECT --subnet management --root-pass acomanacoman --name portdirect


hammer -u admin -p ${FOREMAN_PASSWORD} \
    hostgroup create \
        --architecture x86_64 \
        --ask-root-pass no \
        --domain $(hostname -d) \
        --environment ${ENVIRONMENT_NAME} \
        --operatingsystem "centos 7" \
        --medium "CentOS mirror" \
        --partition-table "Kickstart default" \
        --puppet-ca-proxy "puppet-master.$(hostname -d)" \
        --realm PORT.DIRECT \
        --subnet management \
        --root-pass acomanacoman \
        --name portdirect \
        --puppet-ca-proxy puppet-master.port.direct \
        --puppet-proxy puppet-master.port.direct

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Compute Resources"
################################################################################
foreman-installer \







#
# /usr/sbin/foreman-installer --enable-puppet
#
#
# /usr/sbin/foreman-installer --enable-foreman-proxy --foreman-proxy-tftp=false
#
#

#
#
#
#
#
#
# #
# # ################################################################################
# # echo "${OS_DISTRO}: Setting Up puppet Agent"
# # ################################################################################
# # # crudini doesn't like puppets leading whitespace
# # sed -i -e 's/^[ \t]*//' /etc/puppet/puppet.conf
# # crudini --set /etc/puppet/puppet.conf agent certificate_revocation "false"
# # crudini --set /etc/puppet/puppet.conf agent certname "$(hostname -f)"
#
#
#
#
#
#
#
# #
# #
# #
# #
# #
# # ################################################################################
# # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: IPA SERVER INFO"
# # ################################################################################
# # export IPA_SERVER=$(cat /etc/ipa/default.conf | grep "server" | awk '{print $3}')
# # export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
# # export IPA_BASE_DN=$( cat /etc/openldap/ldap.conf | grep "^BASE " | awk '{print $2}' )
# # export IPA_URI=$( cat /etc/openldap/ldap.conf | grep "^URI " | awk '{print $2}' )
# #
# #
# #
# # ################################################################################
# # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Retreiving KEYTAB for service"
# # ################################################################################
# # KRB5CCNAME=KEYRING:session:get-http-service-keytab \
# #       kinit -k
# # KRB5CCNAME=KEYRING:session:get-http-service-keytab \
# #       /usr/sbin/ipa-getkeytab \
# #           -s ${IPA_SERVER} \
# #           -k /etc/httpd/conf/http.keytab \
# #           -p HTTP/$(hostname -f)
# # kdestroy -c KEYRING:session:get-http-service-keytab
# # chown apache:apache /etc/httpd/conf/http.keytab
# # chmod 0600 /etc/httpd/conf/http.keytab
# #
# #
# # ################################################################################
# # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSSD"
# # ################################################################################
# # crudini --set /etc/sssd/sssd.conf domain/$(hostname -d) ldap_user_extra_attrs "email:mail, lastname:sn, firstname:givenname"
# # crudini --set /etc/sssd/sssd.conf sssd services "nss, sudo, pam, ssh, ifp"
# # crudini --set /etc/sssd/sssd.conf ifp allowed_uids "apache, root"
# # crudini --set /etc/sssd/sssd.conf ifp user_attributes "+email, +firstname, +lastname"
# # systemctl restart sssd
#
#
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Installing Foreman"
# ################################################################################
# /usr/sbin/foreman-installer \
# --foreman-ipa-authentication=true \
# --enable-foreman-plugin-discovery \
# --no-enable-foreman-proxy \
# --no-enable-puppet \
# --foreman-db-type=mysql \
# --foreman-db-database=${FOREMAN_DB_NAME} \
# --foreman-db-username=${FOREMAN_DB_USER} \
# --foreman-db-password=${FOREMAN_DB_PASSWORD} \
# --foreman-db-host=database.$(hostname -d) \
# --foreman-db-manage=false \
# --foreman-email-delivery-method=smtp \
# --foreman-email-smtp-address=${FOREMAN_SMTP_HOST} \
# --foreman-email-smtp-authentication=login \
# --foreman-email-smtp-password="${FOREMAN_SMTP_PASS}" \
# --foreman-email-smtp-port=${FOREMAN_SMTP_PORT} \
# --foreman-email-smtp-user-name="${FOREMAN_SMTP_USER}" \
# --foreman-server-ssl-ca="${FOREMAN_UI_CA}" \
# --foreman-server-ssl-cert="${FOREMAN_UI_CERT}" \
# --foreman-server-ssl-certs-dir="" \
# --foreman-server-ssl-chain="${FOREMAN_UI_CA}" \
# --foreman-server-ssl-crl='' \
# --foreman-server-ssl-key="${FOREMAN_UI_KEY}" \
# --foreman-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
# --foreman-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}" \
# --foreman-proxy-foreman-ssl-ca="${FOREMAN_CA}" \
# --foreman-proxy-foreman-ssl-cert="${FOREMAN_CERT}" \
# --foreman-proxy-foreman-ssl-key="${FOREMAN_KEY}" \
# --foreman-proxy-ssl-ca="${FOREMAN_CA}" \
# --foreman-proxy-ssl-cert="${FOREMAN_CERT}" \
# --foreman-proxy-ssl-key="${FOREMAN_KEY}" \
# --foreman-proxy-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
# --foreman-proxy-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}"
#
#
#
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Installing Foreman"
# ################################################################################
# /usr/sbin/foreman-installer \
# --enable-foreman-plugin-discovery \
# --no-enable-foreman-proxy \
# --enable-puppet \
# --foreman-db-type=mysql \
# --foreman-db-database=${FOREMAN_DB_NAME} \
# --foreman-db-username=${FOREMAN_DB_USER} \
# --foreman-db-password=${FOREMAN_DB_PASSWORD} \
# --foreman-db-host=database.$(hostname -d) \
# --foreman-db-manage=false \
# --foreman-email-delivery-method=smtp \
# --foreman-email-smtp-address=${FOREMAN_SMTP_HOST} \
# --foreman-email-smtp-authentication=login \
# --foreman-email-smtp-password="${FOREMAN_SMTP_PASS}" \
# --foreman-email-smtp-port=${FOREMAN_SMTP_PORT} \
# --foreman-email-smtp-user-name="${FOREMAN_SMTP_USER}" \
# --foreman-server-ssl-ca="${FOREMAN_UI_CA}" \
# --foreman-server-ssl-cert="${FOREMAN_UI_CERT}" \
# --foreman-server-ssl-certs-dir="" \
# --foreman-server-ssl-chain="${FOREMAN_UI_CA}" \
# --foreman-server-ssl-crl='' \
# --foreman-server-ssl-key="${FOREMAN_UI_KEY}" \
# --foreman-proxy-foreman-ssl-ca="${FOREMAN_CA}" \
# --foreman-proxy-foreman-ssl-cert="${FOREMAN_CERT}" \
# --foreman-proxy-foreman-ssl-key="${FOREMAN_KEY}" \
# --foreman-proxy-ssl-ca="${FOREMAN_CA}" \
# --foreman-proxy-ssl-cert="${FOREMAN_CERT}" \
# --foreman-proxy-ssl-key="${FOREMAN_KEY}" \
# --foreman-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
# --foreman-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}" \
# --foreman-proxy-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
# --foreman-proxy-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}"
#
# --foreman-proxy-tftp=false \
# --foreman-proxy-puppetca=true \
# --foreman-proxy-puppetrun=true \
# #
# # ################################################################################
# # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Running Puppet Agent to pupulate host info"
# # ################################################################################
# # puppet agent -t || puppet agent -t
# #
# #
# # ################################################################################
# # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating cirts for proxys"
# # ################################################################################
# # for BRIDGE_DEVICE in master br0 br1 br2; do
# #   (puppet cert list --all | grep -q foreman-proxy-${BRIDGE_DEVICE}.$(hostname -d) ) || puppet cert --generate foreman-proxy-${BRIDGE_DEVICE}.$(hostname -d)
# # done
# #
# #
# #
# #
# #
# #
# # ################################################################################
# # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up discovery"
# # ################################################################################
# # foreman-installer \
# #   --enable-foreman-plugin-discovery \
# #   --foreman-plugin-discovery-install-images=false \
# #   --foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
# #   --foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret
# # cat /var/lib/puppet/ssl/certs/ca.pem > /etc/pki/ca-trust/source/anchors/puppet.pem
# # update-ca-trust enable
# # update-ca-trust
# #
# #
# #
# #
# #
# # ################################################################################
# # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Realm Joining"
# # ################################################################################
# # mkdir -p /etc/foreman-proxy
# # cd /etc/foreman-proxy && \
# #     echo ${IPA_HOST_ADMIN_PASSWORD} | foreman-prepare-realm ${IPA_HOST_ADMIN_USER} realm-proxy
# # chown foreman-proxy /etc/foreman-proxy/freeipa.keytab
# # chmod 600 /etc/foreman-proxy/freeipa.keytab
# #
# #
# # IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
# # foreman-installer \
# # --enable-foreman-proxy \
# # --foreman-proxy-tftp=false \
# # --foreman-proxy-realm=true \
# # --foreman-proxy-realm-keytab="/etc/foreman-proxy/freeipa.keytab" \
# # --foreman-proxy-realm-listen-on="https" \
# # --foreman-proxy-realm-principal="realm-proxy@${IPA_REALM}" \
# # --foreman-proxy-realm-provider "freeipa" \
# # --foreman-proxy-oauth-consumer-key=$oauth_consumer_key \
# # --foreman-proxy-oauth-consumer-secret=$oauth_consumer_secret
