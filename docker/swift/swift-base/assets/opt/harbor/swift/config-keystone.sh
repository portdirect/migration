#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=keystone
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/swift/swift-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg SERVICE_TENANT_NAME SWIFT_KEYSTONE_USER SWIFT_KEYSTONE_PASSWORD \
                    KEYSTONE_AUTH_PROTOCOL KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_ADMIN_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RUNNING"
################################################################################
crudini --set $cfg filter:keystoneauth use "egg:swift#keystoneauth"
crudini --set $cfg filter:keystoneauth operator_roles "admin,user"
crudini --set $cfg filter:keystoneauth paste.filter_factory "keystonemiddleware.auth_token:filter_factory"
crudini --set $cfg filter:keystoneauth auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}"
crudini --set $cfg filter:keystoneauth auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357"
crudini --set $cfg filter:keystoneauth auth_plugin "password"
crudini --set $cfg filter:keystoneauth project_domain_name "default"
crudini --set $cfg filter:keystoneauth user_domain_name "default"
crudini --set $cfg filter:keystoneauth project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:keystoneauth username "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:keystoneauth password "${SWIFT_KEYSTONE_PASSWORD}"
crudini --set $cfg filter:keystoneauth delay_auth_decision "true"


for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg filter:authtoken $option
done
crudini --set $cfg filter:authtoken paste.filter_factory "keystonemiddleware.auth_token:filter_factory"
crudini --set $cfg filter:authtoken auth_plugin "password"
crudini --set $cfg filter:authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg filter:authtoken user_domain_name "default"
crudini --set $cfg filter:authtoken project_domain_name "default"
crudini --set $cfg filter:authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:authtoken username "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:authtoken password "${SWIFT_KEYSTONE_PASSWORD}"
crudini --set $cfg filter:authtoken auth_version "v3"
crudini --set $cfg filter:authtoken delay_auth_decision "true"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: S3 Token Config"
################################################################################

crudini --set $cfg filter:s3token paste.filter_factory "keystonemiddleware.s3_token:filter_factory"
crudini --set $cfg filter:s3token auth_port "35357"
crudini --set $cfg filter:s3token auth_host "${KEYSTONE_ADMIN_SERVICE_HOST}"
crudini --set $cfg filter:s3token auth_protocol "${KEYSTONE_AUTH_PROTOCOL}"
crudini --set $cfg filter:s3token admin_user "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:s3token admin_tenant_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:s3token admin_password "${SWIFT_KEYSTONE_PASSWORD}"
