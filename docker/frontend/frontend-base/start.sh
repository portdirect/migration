#!/bin/bash
set -e
OPENSTACK_COMPONENT="Frontend"
OPENSTACK_SUBCOMPONENT="Base"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Pulling Assets"
################################################################################
git clone ${FRONTEND_REPO} /srv/site


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Building Site"
################################################################################
cd /srv/site && jekyll build --destination /usr/share/nginx/html


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching Webserver"
################################################################################
/usr/sbin/nginx -g "daemon off;"
