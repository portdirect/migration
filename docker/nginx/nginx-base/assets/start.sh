#!/bin/bash
set -e
OPENSTACK_COMPONENT="Proxy"
OPENSTACK_SUBCOMPONENT="Base"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching Webserver"
################################################################################
exec /usr/sbin/nginx -g "daemon off;"
