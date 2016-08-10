#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=api-pipeline
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: API PIPELINES"
################################################################################
export api_paste=/etc/keystone/keystone-paste.ini
crudini --set $api_paste pipeline:public_api pipeline "cors sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension public_service"
crudini --set $api_paste pipeline:admin_api pipeline "cors sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension s3_extension admin_service"
crudini --set $api_paste pipeline:api_v3 pipeline "cors sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension_v3 s3_extension service_v3"
crudini --set $cfg paste_deploy config_file "$api_paste"
