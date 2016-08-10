#!/bin/bash
set -e

################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_USER KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars GLANCE_KEYSTONE_USER GLANCE_KEYSTONE_PASSWORD \
                    GLANCE_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing admin credentials for ${KEYSTONE_ADMIN_USER}"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default



USER=${GLANCE_KEYSTONE_USER}
ROLE=admin
DESCRIPTION="${OS_DISTRO}: ${OPENSTACK_COMPONENT} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${GLANCE_KEYSTONE_PASSWORD}
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: User Management"
################################################################################
openstack user create --or-show \
                      --domain default \
                      --project-domain default \
                      --project ${PROJECT} \
                      --description "${DESCRIPTION}" \
                      --email "${EMAIL}" \
                      --password ${PASSWORD} \
                      --enable \
                      ${USER}
USER_ID=$(openstack user show --domain default \
                              -f value -c id \
                                ${USER})


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Managing User Roles"
################################################################################
openstack role add --user ${USER_ID} \
                --project-domain default \
                --project ${PROJECT} \
                ${ROLE}
openstack role assignment list \
                --project-domain default \
                --project ${PROJECT} \
                --role ${ROLE} \
                --user ${USER_ID}


SERVICE_NAME=glance
SERVICE_TYPE=image
SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Service Management"
################################################################################
SERVICE_ID=$( openstack service list \
            -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )
[[ -z ${SERVICE_ID} ]] && \
    ( openstack service create \
                --name ${SERVICE_NAME} \
                --description "${SERVICE_DESC}" \
                --enable \
                ${SERVICE_TYPE}
    ) || openstack service show ${SERVICE_NAME}



ENDPOINT_URL="https://glance.${OS_DOMAIN}"
for ENDPOINT_INTERFACE in admin internal public
do
  ################################################################################
  echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
  ################################################################################
  ENDPOINT_ID=$( openstack endpoint list \
              -f csv --quote none | grep "$ENDPOINT_INTERFACE,$ENDPOINT_URL\$" | cut -d , -f 1 )

  [[ -z $ENDPOINT_ID ]] || openstack endpoint delete ${ENDPOINT_ID}

  openstack endpoint create --region $DEFAULT_REGION \
                      $SERVICE_NAME \
                      $ENDPOINT_INTERFACE \
                      $ENDPOINT_URL
done
