#!/bin/sh
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
. /opt/harbor/harbor-common.sh
. /opt/harbor/config-cloudkitty.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up storage"
################################################################################
# allow both of these commands to fail.
mkdir -p /var/lib/cloudkitty/locks || true
chown -R ${CLOUDKITTY_USER} /var/lib/cloudkitty || true

tail -f /dev/null
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/sh -c "exec /usr/bin/cloudkitty-processor --debug" ${CLOUDKITTY_USER}
