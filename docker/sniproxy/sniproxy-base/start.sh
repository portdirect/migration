#!/bin/bash
set -e
OPENSTACK_COMPONENT="Proxy"
OPENSTACK_SUBCOMPONENT="Base"
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

LISTEN="0.0.0.0:1443"
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring sniproxy"
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Listening to ${LISTEN}"
################################################################################
ESCAPED_DOMAIN="$(printf ${OS_DOMAIN} | sed 's/\./\\\\\\./')"
cat > /etc/sniproxy.conf <<EOF
user daemon

pidfile /tmp/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

listener ${LISTEN} {
    protocol tls
    table TableName
}

table TableName {
    (.*)-(.*)\\\.open\\\.${ESCAPED_DOMAIN}
}
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching haproxy"
################################################################################
exec sniproxy -c /etc/sniproxy.conf -f
