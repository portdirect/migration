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
: ${NEUTRON_API_SERVICE_PORT:="9696"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_USER KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars NEUTRON_KEYSTONE_USER NEUTRON_KEYSTONE_PASSWORD \
                    NEUTRON_API_SERVICE_HOST NEUTRON_API_SERVICE_PORT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: sourceing Aadmin openrc"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: User Management"
################################################################################

USER=${NEUTRON_KEYSTONE_USER}
ROLE=admin
DESCRIPTION="${OS_DISTRO}: ${OPENSTACK_COMPONENT} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${NEUTRON_KEYSTONE_PASSWORD}

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
openstack role add \
          --user ${USER_ID} \
          --project-domain default \
          --project ${PROJECT} \
          ${ROLE}
openstack role assignment list \
          --project-domain default \
          --project ${PROJECT} \
          --role ${ROLE} \
          --user ${USER_ID}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Service Management"
################################################################################
SERVICE_NAME=neutron
SERVICE_TYPE=network
SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
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

  (
    ENDPOINT_INTERFACE=internal
    ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://neutron.${OS_DOMAIN}"
    ################################################################################
    echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
    ################################################################################
    (
    ENDPOINT_ID=$( openstack endpoint list \
                -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

        [[ -z $ENDPOINT_ID ]] && \
            ( \
            echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $ENDPOINT_URL" \
            ) || ( \
            echo "endpoint found" ; \
            openstack endpoint delete ${ENDPOINT_ID}
            )

        openstack endpoint create --region $DEFAULT_REGION \
                            $SERVICE_NAME \
                            $ENDPOINT_INTERFACE \
                            $ENDPOINT_URL
    )

    ENDPOINT_INTERFACE=admin
    ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://neutron.${OS_DOMAIN}"
    ################################################################################
    echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
    ################################################################################
    (
    ENDPOINT_ID=$( openstack endpoint list \
                -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

        [[ -z $ENDPOINT_ID ]] && \
            ( \
            echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $ENDPOINT_URL" \
            ) || ( \
            echo "endpoint found" ; \
            openstack endpoint delete ${ENDPOINT_ID}
            )

        openstack endpoint create --region $DEFAULT_REGION \
                            $SERVICE_NAME \
                            $ENDPOINT_INTERFACE \
                            $ENDPOINT_URL
    )


    ENDPOINT_INTERFACE=public
    ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://neutron.${OS_DOMAIN}"
    ################################################################################
    echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
    ################################################################################
    (
    ENDPOINT_ID=$( openstack endpoint list \
                -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

        [[ -z $ENDPOINT_ID ]] && \
            ( \
            echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $ENDPOINT_URL" \
            ) || ( \
            echo "endpoint found" ; \
            openstack endpoint delete ${ENDPOINT_ID}
            )

        openstack endpoint create --region $DEFAULT_REGION \
                            $SERVICE_NAME \
                            $ENDPOINT_INTERFACE \
                            $ENDPOINT_URL
    )
  )
)
