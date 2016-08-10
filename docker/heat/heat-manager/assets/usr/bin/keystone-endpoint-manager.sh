#!/bin/bash
set -e

################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
: ${HEAT_DOMAIN:="heat"}

. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_USER KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars HEAT_KEYSTONE_USER HEAT_KEYSTONE_PASSWORD \
                    HEAT_API_SERVICE_HOST HEAT_API_CFN_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing admin credentials for ${KEYSTONE_ADMIN_USER}"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: User Management"
################################################################################
USER=${HEAT_KEYSTONE_USER}
ROLE=admin
DESCRIPTION="${OS_DISTRO}: ${OPENSTACK_COMPONENT} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${HEAT_KEYSTONE_PASSWORD}

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
(
openstack role add --user ${USER_ID} \
                --project-domain default \
                --project ${PROJECT} \
                ${ROLE}
openstack role assignment list \
                --project-domain default \
                --project ${PROJECT} --role ${ROLE} --user ${USER_ID}
)




################################################################################
echo "${OS_DISTRO}: Heat-API: Managing \"${HEAT_DOMAIN}\" domain"
################################################################################
openstack domain create --or-show \
              --description "${OS_DISTRO}: Heat Domain" \
              ${HEAT_DOMAIN}

HEAT_DOMAIN_ID=$( openstack domain show -f value -c id ${HEAT_DOMAIN} )



################################################################################
echo "${OS_DISTRO}: Heat-API: ETCD set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/heat-domain-id ${HEAT_DOMAIN_ID}"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/heat-domain-id "${HEAT_DOMAIN_ID}"






(

  ################################################################################
  echo "${OS_DISTRO}: Heat-API: Managing domain admin"
  ################################################################################
  (
    USER="${HEAT_KEYSTONE_USER}_admin"
    ROLE=admin
    DESCRIPTION="${OS_DISTRO}: ${USER} user"
    EMAIL="${USER}@${OS_DOMAIN}"
    PROJECT=${SERVICE_TENANT_NAME}
    PASSWORD=${HEAT_KEYSTONE_PASSWORD}

    openstack user create --or-show \
                          --domain ${HEAT_DOMAIN} \
                          --description "${DESCRIPTION}" \
                          --email "${EMAIL}" \
                          --password ${PASSWORD} \
                          --enable \
                          ${USER}

  USER_ID=$(openstack user show --domain ${HEAT_DOMAIN} \
                                              -f value -c id \
                                                ${USER})

    (
          openstack role add --domain ${HEAT_DOMAIN} \
                             --user ${USER_ID} \
                             ${ROLE}
        openstack role assignment list --user ${USER_ID}
    )
  )
)





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Service Management"
################################################################################
SERVICE_NAME=heat
SERVICE_TYPE=orchestration
SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://heat.${OS_DOMAIN}/v1/%(tenant_id)s"
INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://heat.${OS_DOMAIN}/v1/%(tenant_id)s"
ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://heat.${OS_DOMAIN}/v1/%(tenant_id)s"
(
  (
    (
      SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )
      [[ -z ${SERVICE_ID} ]] && \
          ( \
          echo "Service for $SERVICE_NAME not found, creating now" ; \
          openstack service create \
                      --name ${SERVICE_NAME} \
                      --description "${SERVICE_DESC}" \
                      --enable \
                      ${SERVICE_TYPE}

          SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )

          ) || ( \
              openstack service show ${SERVICE_NAME} \
          )
    )

    SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )

    (
      ENDPOINT_INTERFACE=internal
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $INTERNAL_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $INTERNAL_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=admin
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $ADMIN_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $ADMIN_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=public
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $PUBLIC_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $PUBLIC_ENDPOINT_URL
    )
  )
)







################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Service Management"
################################################################################
(
  SERVICE_NAME=heat-cfn
  SERVICE_TYPE=cloudformation
  SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
  PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${SERVICE_NAME}.${OS_DOMAIN}/v1"
  INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${SERVICE_NAME}.${OS_DOMAIN}/v1"
  ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${SERVICE_NAME}.${OS_DOMAIN}/v1"
  (
    (
      SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )
      [[ -z ${SERVICE_ID} ]] && \
          ( \
          echo "Service for $SERVICE_NAME not found, creating now" ; \
          openstack service create \
                      --name ${SERVICE_NAME} \
                      --description "${SERVICE_DESC}" \
                      --enable \
                      ${SERVICE_TYPE}

          ) || ( \
              openstack service show ${SERVICE_NAME} \
          )
    )

    SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )

    (
      ENDPOINT_INTERFACE=internal
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $INTERNAL_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $INTERNAL_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=admin
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $ADMIN_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $ADMIN_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=public
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $PUBLIC_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $PUBLIC_ENDPOINT_URL
      )
  )
)
