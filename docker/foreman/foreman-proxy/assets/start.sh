#!/bin/bash
set -e
export OS_DISTRO=HarborOS
################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


BRIDGE_DEVICE=$(hostname -s | awk -F '-proxy-' '{ print $2 }')
################################################################################
echo "${OS_DISTRO}: Waiting for the interface ${BRIDGE_DEVICE} to become active"
################################################################################
pipework --wait -i ${BRIDGE_DEVICE}


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
  update-ca-trust enable
  update-ca-trust
fi
systemctl enable certmonger
systemctl start certmonger



################################################################################
echo "${OS_DISTRO}: Setting up puppet agent"
################################################################################
cat > /etc/puppet/puppet.conf <<EOF
[main]
    # define the fqdn of the puppet master
    server = puppet-master.$(hostname -d)

    # The Puppet log directory.
    # The default value is '$vardir/log'.
    logdir = /var/log/puppet

    # Where Puppet PID files are kept.
    # The default value is '$vardir/run'.
    rundir = /var/run/puppet

    # Where SSL certificates are kept.
    # The default value is '$confdir/ssl'.
    ssldir = \$vardir/ssl

[agent]
    # The file in which puppetd stores a list of the classes
    # associated with the retrieved configuratiion.  Can be loaded in
    # the separate ``puppet`` executable using the ``--loadclasses``
    # option.
    # The default value is '\$confdir/classes.txt'.
    classfile = \$vardir/classes.txt

    # Where puppetd caches the local configuration.  An
    # extension indicating the cache format is added automatically.
    # The default value is '\$confdir/localconfig'.
    localconfig = \$vardir/localconfig
EOF

puppet agent --test || (
    mkdir -p /root/.ssh
    cat /var/pod/auth/puppetmaster/id_rsa > /root/.ssh/id_rsa
    chmod 0600 /root/.ssh/id_rsa
    ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa root@puppet-master.$(hostname -d) puppet cert clean $(hostname -f)
    rm -f /root/.ssh/id_rsa
    find /var/lib/puppet/ssl -name $(hostname -f).pem -delete
    puppet agent --test )
systemctl start puppet
systemctl enable puppet



export LANG=en_US.UTF-8
BRIDGE_DEVICE=$(hostname -s | awk -F '-proxy-' '{ print $2 }')
################################################################################
echo "${OS_DISTRO}: Installing Smart proxy for ${BRIDGE_DEVICE}"
################################################################################
if [[ "$BRIDGE_DEVICE" == "br0" ]]; then
  mkdir -p /var/lib/tftpboot/boot
  cat /opt/fdi-image-latest.tar | tar x --overwrite -C /var/lib/tftpboot/boot
  cat /opt/CentOS-7.2-x86_64-initrd.img > /var/lib/tftpboot/boot/CentOS-7.2-x86_64-initrd.img
  cat /opt/CentOS-7.2-x86_64-vmlinuz > /var/lib/tftpboot/boot/CentOS-7.2-x86_64-vmlinuz
  chown -R foreman-proxy:foreman-proxy /var/lib/tftpboot/boot/


  ls -lah /var/lib/tftpboot/pxelinux.cfg/default || (
  mkdir -p /var/lib/tftpboot/pxelinux.cfg
  cp /opt/tftpboot/pxelinux.cfg/default /var/lib/tftpboot/pxelinux.cfg/default
  sed -i "s/{{ FOREMAN_API_HOST }}/foreman.$(hostname -d)/" /var/lib/tftpboot/pxelinux.cfg/default
  chown foreman-proxy:foreman-proxy /var/lib/tftpboot/pxelinux.cfg/default
  chown -R foreman-proxy:foreman-proxy /var/lib/tftpboot
  )

  BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
  IP_START=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".1.0"}')
  IP_END=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".255.0"}')
  GATEWAY_IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".0.1"}')
  REVERSE_ZONE=$(echo ${GATEWAY_IP} | awk -F. '{print $3"." $2"."$1".in-addr.arpa"}')
  FREEIPA_SERVER_IP=$(ping -c 1 freeipa-master.$(hostname -d) | awk -F" |:" '/from/{print $4}')

  foreman-installer \
    --no-enable-foreman \
    --no-enable-foreman-cli \
    --no-enable-foreman-plugin-bootdisk \
    --no-enable-foreman-plugin-setup \
    --no-enable-puppet \
    --enable-foreman-proxy \
    --enable-foreman-proxy-plugin-discovery \
    --foreman-proxy-puppetca=false \
    --foreman-proxy-puppetrun=false \
    --foreman-proxy-puppet-ssl-ca="$(puppet agent --configprint localcacert)" \
    --foreman-proxy-puppet-ssl-cert="$(puppet agent --configprint hostcert)" \
    --foreman-proxy-puppet-ssl-key="$(puppet agent --configprint hostprivkey)" \
    --foreman-proxy-puppet-url="https://puppet-master.$(hostname -d):8140" \
    --foreman-proxy-tftp=true \
    --foreman-proxy-tftp-servername=${BRIDGE_IP} \
    --foreman-proxy-dhcp=true \
    --foreman-proxy-dhcp-interface=${BRIDGE_DEVICE} \
    --foreman-proxy-dhcp-gateway=${GATEWAY_IP} \
    --foreman-proxy-dhcp-range="${IP_START} ${IP_END}" \
    --foreman-proxy-dhcp-nameservers="${FREEIPA_SERVER_IP}" \
    --foreman-proxy-foreman-base-url=https://foreman.$(hostname -d) \
    --foreman-proxy-trusted-hosts=foreman.$(hostname -d) \
    --foreman-proxy-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
    --foreman-proxy-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}" \
    --foreman-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
    --foreman-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}"
else
  BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
  IP_START=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".1.0"}')
  IP_END=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".255.0"}')
  GATEWAY_IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2".0.1"}')
  REVERSE_ZONE=$(echo ${GATEWAY_IP} | awk -F. '{print $3"." $2"."$1".in-addr.arpa"}')
  FREEIPA_SERVER_IP=$(ping -c 1 freeipa-master.$(hostname -d) | awk -F" |:" '/from/{print $4}')
  foreman-installer \
    --no-enable-foreman \
    --no-enable-foreman-cli \
    --no-enable-foreman-plugin-bootdisk \
    --no-enable-foreman-plugin-setup \
    --no-enable-puppet \
    --enable-foreman-proxy \
    --foreman-proxy-puppetca=false \
    --foreman-proxy-puppetrun=false \
    --foreman-proxy-tftp=false \
    --foreman-proxy-dhcp=true \
    --foreman-proxy-dhcp-interface=${BRIDGE_DEVICE} \
    --foreman-proxy-dhcp-gateway='' \
    --foreman-proxy-dhcp-range="${IP_START} ${IP_END}" \
    --foreman-proxy-dhcp-nameservers="${FREEIPA_SERVER_IP}" \
    --foreman-proxy-puppet-ssl-ca="$(puppet agent --configprint localcacert)" \
    --foreman-proxy-puppet-ssl-cert="$(puppet agent --configprint hostcert)" \
    --foreman-proxy-puppet-ssl-key="$(puppet agent --configprint hostprivkey)" \
    --foreman-proxy-puppet-url="https://puppet-master.$(hostname -d):8140" \
    --foreman-proxy-foreman-base-url=https://foreman.$(hostname -d) \
    --foreman-proxy-trusted-hosts=foreman.$(hostname -d) \
    --foreman-proxy-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
    --foreman-proxy-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}" \
    --foreman-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
    --foreman-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}"
fi
puppet agent --test
