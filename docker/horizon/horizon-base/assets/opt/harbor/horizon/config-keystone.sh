#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=keystone
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
                    KEYSTONE_ADMIN_SERVICE_HOST \
                    KEYSTONE_AUTH_PROTOCOL \
                    OS_DOMAIN \
                    ETCDCTL_ENDPOINT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Default Domain ID from ETCD"
################################################################################
IPA_DOMAIN_ID=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/os-keystone/default_domain_id)
check_required_vars IPA_DOMAIN_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${KEYSTONE_ADMIN_SERVICE_HOST}\"/g" $cfg
sed -i "s,OPENSTACK_KEYSTONE_URL = \"http://%s:5000/v2.0\" % OPENSTACK_HOST,OPENSTACK_KEYSTONE_URL = \"${KEYSTONE_AUTH_PROTOCOL}://%s/v3\" % OPENSTACK_HOST,g" $cfg
sed -i "s/#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g" $cfg
sed -i "s/#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = \"${IPA_DOMAIN_ID}\"/g" $cfg
sed -i "s/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"_member_\"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"/g" $cfg
#sed -i "s/'name': 'native'/'name': 'ldap'/g" $cfg
#sed -i "s/'can_edit_user': True/'can_edit_user': False/g" $cfg
sed -i "s/#OPENSTACK_KEYSTONE_FEDERATION_MANAGEMENT = False/OPENSTACK_KEYSTONE_FEDERATION_MANAGEMENT = True/" $cfg

cat >> $cfg <<EOF
WEBSSO_ENABLED = True
WEBSSO_CHOICES = (
  ("saml2", _("${OS_DOMAIN}: Port Authority")),
  ("credentials", _("${OS_DOMAIN}: Keystone Credentials"))
)
WEBSSO_INITIAL_CHOICE = "saml2"
EOF
