#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${HORIZON_CONSOLE:="SERIAL"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars HORIZON_DB_NAME HORIZON_DB_USER HORIZON_DB_PASSWORD MARIADB_SERVICE_HOST \
                    KEYSTONE_ADMIN_SERVICE_HOST

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################

fail_unless_os_service_running keystone




export cfg=/etc/openstack-dashboard/local_settings
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/horizon/config-database.sh
/opt/harbor/horizon/config-keystone.sh
/opt/harbor/horizon/config-ssl.sh
/opt/harbor/horizon/config-api-versions.sh
/opt/harbor/horizon/config-branding.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
#sed -i '1i# encoding: utf-8' $cfg


sed -i "s,WEBROOT = '/dashboard/',WEBROOT = '/',g" $cfg
sed -i "s,DEBUG = False,DEBUG = True,g" $cfg

#sed -i "s,#CUSTOM_THEME_PATH = 'themes/default',CUSTOM_THEME_PATH = 'themes/harbor',g" /etc/openstack-dashboard/local_settings
#sed -i "s,#DISALLOW_IFRAME_EMBED = True,DISALLOW_IFRAME_EMBED = False,g" $cfg

#sed -i "s/#LAUNCH_INSTANCE_LEGACY_ENABLED = True/LAUNCH_INSTANCE_LEGACY_ENABLED = False/g" $cfg
#sed -i "s/#LAUNCH_INSTANCE_NG_ENABLED = False/LAUNCH_INSTANCE_NG_ENABLED = True/g" $cfg

sed -i "s/#CONSOLE_TYPE = \"AUTO\"/CONSOLE_TYPE = \"${HORIZON_CONSOLE}\"/g" $cfg
sed -i "s/'can_set_password': False,/'can_set_password': True,/g" $cfg
