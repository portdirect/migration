#!/bin/bash

OPENSTACK_COMPONENT=freeipa
OPENSTACK_SUBCOMPONENT=master

source /etc/os-common/common.env
source /etc/${OPENSTACK_COMPONENT}/master.env
source /etc/${OPENSTACK_COMPONENT}/credentials-admin.env
source /etc/${OPENSTACK_COMPONENT}/credentials-ds.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Status"
################################################################################
etcdctl set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/status MAINTENANCE

cfg=/etc/${OPENSTACK_COMPONENT}/${OPENSTACK_SUBCOMPONENT}.yml
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
################################################################################
cp -f /etc/${OPENSTACK_COMPONENT}/${OPENSTACK_SUBCOMPONENT}.template.yml $cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: OS_DISTRO"
################################################################################
sed -i "s/{{OS_DISTRO}}/${OS_DISTRO}/" $cfg
sed -i "s/{{OS_RELEASE}}/${OS_RELEASE}/" $cfg
sed -i "s/{{OS_REGISTRY}}/${OS_REGISTRY}/" $cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring"
################################################################################
sed -i "s/{{IPA_MASTER_HOSTNAME}}/${IPA_MASTER_HOSTNAME}/" $cfg
sed -i "s/{{OS_DOMAIN}}/${OS_DOMAIN}/" $cfg
sed -i "s/{{IPA_UPSTREAM_DNS}}/${IPA_UPSTREAM_DNS}/" $cfg
sed -i "s,{{IPA_DATA_DIR}},${IPA_DATA_DIR}," $cfg


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Pinning Container to this node"
################################################################################
sed -i "s,{{IPA_MASTER_NODE}},$(hostname)," $cfg







################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensureing Data Exists"
################################################################################
mkdir -p ${IPA_DATA_DIR}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Copying Config Into Place"
################################################################################
cat > ${IPA_DATA_DIR}/ipa-server-install-options << EOF
--ds-password=${IPA_DS_PASSWORD}
--admin-password=${IPA_ADMIN_PASSWORD}
EOF

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring permissions are correct"
################################################################################
chcon -t svirt_sandbox_file_t ${IPA_DATA_DIR}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Chronyd"
################################################################################
LINE='port 0'
cfg=/etc/chrony.conf
grep -q "$LINE" "$cfg" || ( echo "$LINE" >> "$cfg" && systemctl restart chronyd)
