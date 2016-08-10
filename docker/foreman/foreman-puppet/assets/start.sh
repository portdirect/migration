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
  update-ca-trust enable
  update-ca-trust
fi
systemctl enable certmonger
systemctl start certmonger



################################################################################
echo "${OS_DISTRO}: Setting up ssh"
################################################################################
systemctl enable sshd
systemctl start sshd
echo n | ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa && \
cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys && \
mkdir -p /var/pod/auth/puppetmaster && \
cat /root/.ssh/id_rsa > /var/pod/auth/puppetmaster/id_rsa



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Puppet CA"
################################################################################
sed -i "s/{{ HOSTNAME }}/$(hostname -f)/" /etc/httpd/conf.d/puppetmaster.conf
(puppet master --debug --no-daemonize& sleep 10; kill $!) || true

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



################################################################################
echo "${OS_DISTRO}: Launching: Apache via systemd"
################################################################################
systemctl enable httpd
systemctl start httpd



################################################################################
echo "${OS_DISTRO}: Setting up puppet agent"
################################################################################
puppet agent --test || true
systemctl start puppet
systemctl enable puppet


################################################################################
echo "${OS_DISTRO}: Boostrapping Smart Proxy"
################################################################################
until curl --fail https://foreman.$(hostname -d)
do
  echo "Waiting for Foreman"
  sleep 20s
done


################################################################################
echo "${OS_DISTRO}: Installing Smart Proxy"
################################################################################
export LANG=en_US.UTF-8
until foreman-installer \
  --no-enable-foreman \
  --no-enable-foreman-cli \
  --no-enable-foreman-plugin-bootdisk \
  --no-enable-foreman-plugin-setup \
  --no-enable-puppet \
  --enable-foreman-proxy \
  --foreman-proxy-tftp=false \
  --foreman-proxy-puppetca=true \
  --foreman-proxy-puppetrun=true \
  --foreman-proxy-puppet-ssl-ca="$(puppet agent --configprint localcacert)" \
  --foreman-proxy-puppet-ssl-cert="$(puppet agent --configprint hostcert)" \
  --foreman-proxy-puppet-ssl-key="$(puppet agent --configprint hostprivkey)" \
  --foreman-proxy-puppet-url="https://puppet-master.$(hostname -d):8140" \
  --foreman-proxy-foreman-base-url=https://foreman.$(hostname -d) \
  --foreman-proxy-trusted-hosts=foreman.$(hostname -d) \
  --foreman-proxy-oauth-consumer-key="${FOREMAN_OAUTH_KEY}" \
  --foreman-proxy-oauth-consumer-secret="${FOREMAN_OAUTH_SECRET}"
do
  echo "Waiting for Foreman"
  sleep 120s
done



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up Puppet for foreman"
################################################################################
cat > /etc/puppet/foreman.yaml <<EOF
---
# Update for your Foreman and Puppet master hostname(s)
:url: "https://foreman.$(hostname -d)"
:ssl_ca: "/etc/ipa/ca.crt"
:ssl_cert: "/var/lib/puppet/ssl/certs/$(hostname -f).pem"
:ssl_key: "/var/lib/puppet/ssl/private_keys/$(hostname -f).pem"

# Advanced settings
:puppetdir: "/var/lib/puppet"
:puppetuser: "puppet"
:facts: true
:timeout: 10
:threads: null
EOF

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

    # Send reports to foreman
    reports  = log, foreman
    external_nodes = /etc/puppet/node.rb
    node_terminus = exec

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
systemctl restart httpd
