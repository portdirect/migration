#!/bin/bash
set -e
(
################################################################################
echo "HarborOS (c) 2015 Pete Birley"
################################################################################
)

: ${OS_DOMAIN:="$(hostname -d)"}
: ${FREE_IPA_MASTER_HOSTNAME:="freeipa-master"}
################################################################################
echo "${OS_DISTRO}: IPA: Configuring hosts file"
################################################################################

hostname ${FREE_IPA_MASTER_HOSTNAME}
ETH0_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
cat > /etc/hosts <<EOF
# Harbor-managed hosts file.
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
fe00::0 ip6-mcastprefix
fe00::1 ip6-allnodes
fe00::2 ip6-allrouters
${ETH0_IP} ${FREE_IPA_MASTER_HOSTNAME}.${OS_DOMAIN} ${FREE_IPA_MASTER_HOSTNAME}
EOF


################################################################################
echo "${OS_DISTRO}: IPA: Applying Branding"
################################################################################

sed -i "s/{{BRAND}}/${OS_DOMAIN}/g" /usr/share/ipa/ui/index.html
sed -i "s/{{BRAND}}/${OS_DOMAIN}/g" /usr/share/ipa/ui/reset_password.html

################################################################################
echo "${OS_DISTRO}: Launching FreeIPA"
################################################################################
exec /usr/sbin/ipa-server-configure-first
