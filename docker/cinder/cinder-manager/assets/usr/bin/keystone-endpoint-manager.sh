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


check_required_vars CINDER_KEYSTONE_USER CINDER_KEYSTONE_PASSWORD \
                    CINDER_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing admin credentials for ${KEYSTONE_ADMIN_USER}"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default


USER=${CINDER_KEYSTONE_USER}
ROLE="admin"
DESCRIPTION="${OS_DISTRO}: ${USER} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${CINDER_KEYSTONE_PASSWORD}
################################################################################
echo "${OS_DISTRO}: Cinder: Managing User Accounts"
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
echo "${OS_DISTRO}: Cinder: Managing User Roles"
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


SERVICE_NAME=cinder
SERVICE_TYPE=volume
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


ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${CINDER_API_SERVICE_HOST}/v1/%(tenant_id)s"
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


SERVICE_NAME=cinderv2
SERVICE_TYPE=volumev2
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


ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${CINDER_API_SERVICE_HOST}/v2/%(tenant_id)s"
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
