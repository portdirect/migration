#!/bin/bash
OPENSTACK_SUBCOMPONENT=image-builder
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

tail -f /dev/null
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/bash -c "cd ~ && ./build.sh" trove-agent
