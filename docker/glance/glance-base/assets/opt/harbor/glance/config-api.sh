#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=database
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg \
                    OS_DOMAIN \
                    DEFAULT_REGION \
                    SERVICE_TENANT_NAME \
                    GLANCE_KEYSTONE_USER \
                    GLANCE_KEYSTONE_PASSWORD \
                    KEYSTONE_AUTH_PROTOCOL \
                    KEYSTONE_PUBLIC_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Glance: API"
################################################################################
crudini --set $cfg DEFAULT notification_driver "messaging"
crudini --set $cfg DEFAULT notifier_strategy "rabbit"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: API to Registry"
################################################################################
crudini --set $cfg DEFAULT registry_host "glance-registry.${OS_DOMAIN}"
crudini --set $cfg DEFAULT registry_port "443"
crudini --set $cfg DEFAULT registry_client_protocol "https"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: STORAGE BACKENDS"
################################################################################
crudini --set $cfg glance_store stores "swift,file,http"
crudini --set $cfg glance_store default_store "file"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: STORAGE BACKENDS: SWIFT"
################################################################################
crudini --set $cfg glance_store swift_store_create_container_on_put "True"
# This seems to be required in both places as of 17/5/16, though docs state that it should only be in DEFAULT
crudini --set $cfg DEFAULT swift_store_config_file "/etc/glance/swift_store_config_file.conf"
crudini --set $cfg glance_store swift_store_config_file "/etc/glance/swift_store_config_file.conf"
cat > /etc/glance/swift_store_config_file.conf <<EOF
[${DEFAULT_REGION}]
user = ${SERVICE_TENANT_NAME}:${GLANCE_KEYSTONE_USER}
key = ${GLANCE_KEYSTONE_PASSWORD}
user_domain_name = default
project_domain_name = default
auth_version = 3
auth_address = ${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3
EOF
crudini --set $cfg glance_store default_swift_reference "${DEFAULT_REGION}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Adding Docker support"
################################################################################
crudini --set $cfg DEFAULT container_formats "ami,ari,aki,bare,ovf,ova,docker"
