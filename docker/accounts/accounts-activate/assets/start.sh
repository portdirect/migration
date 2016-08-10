#!/bin/bash
set -e
OPENSTACK_COMPONENT="Frontend"
OPENSTACK_SUBCOMPONENT="CommunityPortal"

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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars PORTAL_DEFAULT_FROM_EMAIL OS_DOMAIN
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring Email"
################################################################################
/opt/harbor/accounts/activate/config-email.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Writing OpenRC"
################################################################################
/opt/harbor/accounts/activate/write-domain-openrc.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting UP EMAIL templates"
################################################################################
sed -i "s/{{ EMAIL }}/${PORTAL_DEFAULT_FROM_EMAIL}/" /srv/mail/blank-slate/*
sed -i "s/{{ OS_DOMAIN }}/${OS_DOMAIN}/" /srv/mail/blank-slate/*
sed -i "s,{{ RESET_PASSWORD_LINK }},https://accounts.${OS_DOMAIN}/request_reset," /srv/mail/blank-slate/*
sed -i "s/{{ OS_DOMAIN }}/$(hostname -d)/" /srv/mail/blank-slate/conv.html

tail -f /dev/null
export SWEEP_INTERVAL=120
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Running user activation script every ${SWEEP_INTERVAL} seconds"
################################################################################
while true; do
    /opt/harbor/accounts/activate/activate-staged-users.sh
    sleep $SWEEP_INTERVAL
done
