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



export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_TOKEN \
                    KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_ADMIN_SERVICE_PORT \
                    KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_PORT \
                    IPA_REALM
dump_vars





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue


#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up admin group"
# ################################################################################
# KEYSTONE_ADMIN_GROUP="$(openstack group create --domain default --description "${OS_DISTRO}: federation admins" --or-show admins -f value -c id)"
# openstack role add  --project ${KEYSTONE_ADMIN_PROJECT} --group ${KEYSTONE_ADMIN_GROUP} admin
# openstack group show $KEYSTONE_ADMIN_GROUP
#
# KEYSTONE_USERS_PROJECT=users
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${KEYSTONE_USERS_PROJECT} Project"
# ################################################################################
# openstack --os-identity-api-version 3 \
#           --os-url ${SERVICE_ENDPOINT} \
#           --os-token ${SERVICE_TOKEN}  \
#           project create --or-show \
#                 --domain default \
#                 --description "${OS_DISTRO}: ${KEYSTONE_USERS_PROJECT} project" \
#                 --enable \
#                 ${KEYSTONE_USERS_PROJECT}
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up ipausers group"
# ################################################################################
# KEYSTONE_USER_GROUP="$(openstack group create --domain default --description "${OS_DISTRO}: federation users" --or-show ipausers -f value -c id)"
# openstack role add  --project ${KEYSTONE_USERS_PROJECT} --group ${KEYSTONE_ADMIN_GROUP} user
# openstack group show $KEYSTONE_USER_GROUP
#

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up ipsilon as an id provider"
################################################################################
openstack identity provider show ipsilon || \
    openstack identity provider create --enable ipsilon --remote-id https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating Mapping"
################################################################################
openstack mapping show ipsilon_mapping || ( \
# cat > /tmp/ipsilon_mapping.json << EOF
# [
#     {
#         "local": [
#             {
#                 "user": {
#                     "name": "{0}"
#                 },
#                 "group": {
#                     "id": "$KEYSTONE_ADMIN_GROUP"
#                 }
#             }
#         ],
#         "remote": [
#             {
#                 "type": "MELLON_NAME_ID"
#             }
#         ]
#     }
# ]
# EOF
#
#openstack mapping delete ipsilon_mapping
cat > /tmp/ipsilon_mapping.json << EOF
[
  {
      "local": [
          {
              "user": {
                  "name": "{0}",
                  "type": "local",
                  "domain": {
                                "name": "${IPA_REALM}"
                            }
              },
              "groups": "{1}",
              "domain": {
                            "name": "${IPA_REALM}"
                        }
          }
      ],
      "remote": [
          {
              "type": "MELLON_NAME_ID"
          },
          {
              "type": "MELLON_groups"
          }
      ]
  }
]
EOF

openstack mapping create --rules /tmp/ipsilon_mapping.json ipsilon_mapping

)

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating Federated protocol"
################################################################################
openstack federation protocol show --identity-provider ipsilon saml2 || \
    openstack federation protocol create --identity-provider ipsilon --mapping ipsilon_mapping saml2


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up ipausers group"
################################################################################
#KEYSTONE_USER_GROUP="$(openstack group create --domain default --description "${OS_DISTRO}: federation users" --or-show ipausers -f value -c id)"

IPA_GROUP=ipausers
KEYSTONE_PROJECT=${IPA_GROUP}
openstack group show --domain ${IPA_REALM} ${IPA_GROUP}
openstack project create --or-show --domain ${IPA_REALM} ${KEYSTONE_PROJECT}
openstack role add --project-domain ${IPA_REALM} --project ${KEYSTONE_PROJECT} --group-domain ${IPA_REALM} --group ${IPA_GROUP} user


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up admins group"
################################################################################
IPA_GROUP=admins
KEYSTONE_PROJECT=${IPA_GROUP}
openstack group show --domain ${IPA_REALM} ${IPA_GROUP}
openstack project create --or-show --domain ${IPA_REALM} ${KEYSTONE_PROJECT}
openstack role add --project-domain ${IPA_REALM} --project ${KEYSTONE_PROJECT} --group-domain ${IPA_REALM} --group ${IPA_GROUP} admin


# openstack group list --domain PORT.DIRECT ipausers
# openstack project create --domain PORT.DIRECT ipausers
# openstack role add --project-domain PORT.DIRECT --project ipausers --group-domain PORT.DIRECT --group ipausers user
#
# openstack group show --domain PORT.DIRECT test-project
# openstack project create --domain PORT.DIRECT test-project
# openstack role add --project-domain PORT.DIRECT --project test-project --group-domain PORT.DIRECT --group test-project user
#
# openstack group show --domain PORT.DIRECT test-project
# openstack project create --domain PORT.DIRECT test-project2
# openstack role add --project-domain PORT.DIRECT --project test-project2 --group-domain PORT.DIRECT --group test-project user
