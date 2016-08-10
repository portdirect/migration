#!/bin/bash
set -e
OPENSTACK_COMPONENT="Proxy"
OPENSTACK_SUBCOMPONENT="Frontend"

HORIZON_INTERNAL=os-horizon-api
HORIZON_EXTERNAL=api.port.direct
MASS_INTERNAL=os-tenant-proxy
MASS_EXTERNAL=open.port.direct

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Horizon"
################################################################################
sed -i "s/{{HORIZON_INTERNAL}}/${HORIZON_INTERNAL}/" /etc/nginx/conf.d/horizon.conf
sed -i "s/{{HORIZON_EXTERNAL}}/${HORIZON_EXTERNAL}/" /etc/nginx/conf.d/horizon.conf


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Mass"
################################################################################
sed -i "s/{{MASS_INTERNAL}}/${MASS_INTERNAL}/" /etc/nginx/conf.d/mass.conf
sed -i "s/{{MASS_EXTERNAL}}/${MASS_EXTERNAL}/" /etc/nginx/conf.d/mass.conf


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching Webserver"
################################################################################
exec /usr/sbin/nginx -g "daemon off;"
