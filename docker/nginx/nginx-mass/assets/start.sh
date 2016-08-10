#!/bin/bash
set -e
OPENSTACK_COMPONENT="Proxy"
OPENSTACK_SUBCOMPONENT="Mass"


: ${OPENSTACK_PUBLIC_RANGE:="16"}
: ${OPENSTACK_PUBLIC_NET:="100.64.0.0"}
: ${DOMAIN:="open"}
: ${OS_DOMAIN:="port.direct"}
: ${GATEWAY_IP:="100.64.0.1"}
: ${EXTERNAL_POOL_START:="100.64.1.1"}
: ${EXTERNAL_POOL_END:="100.64.254.254"}




EXTERNAL_NET="${OPENSTACK_PUBLIC_NET}/${OPENSTACK_PUBLIC_RANGE}"


# This regex will set up a reverse proxy servering INTERNAL_IP:PORT at INTERNAL_IP-PORT.DOMAIN.OS_DOMAIN
HOSTNAME_REGEX="~^(?<internal>$(rgxg cidr $EXTERNAL_NET))\-(?<port>$(rgxg range 1 65535)+)\.(?<domain>[w.^$DOMAIN]+)\.(?<tld>[w.^$OS_DOMAIN]+)\$"

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Hostname Regex: ${HOSTNAME_REGEX}"
echo "-------------------------------------------------------------------------"
export DNS_SERVER=$(nslookup 127.0.0.1 | grep Server | awk -F' ' '{print $2}')
echo "${OS_DISTRO}: DNS Server: ${DNS_SERVER}"
echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: OPENSTACK_PUBLIC_IP_RANGE: ${OPENSTACK_PUBLIC_IP_RANGE}"
echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: DOMAIN: ${DOMAIN}.${OS_DOMAIN}"
echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: FORMAT: INTERNAL_IP-PORT.${DOMAIN}.${OS_DOMAIN} -->> INTERNAL_IP:PORT"
echo "-------------------------------------------------------------------------"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Mass"
################################################################################
sed -i "s/{{SERVER_NAME}}/${HOSTNAME_REGEX}/" /etc/nginx/conf.d/default.conf


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching Webserver"
################################################################################
exec /usr/sbin/nginx -g "daemon off;"
