#!/bin/bash

OPENSTACK_COMPONENT=os-mongodb
OPENSTACK_SUBCOMPONENT=preflight-mongodb



TEMPLATE_DIR=/etc/os-mongodb/kube
OUTPUT_DIR=/etc/os-mongodb/kube

source /etc/os-common/common.env
source /etc/kubernetes/kubernetes.env
source /etc/freeipa/credentials-client-provisioning.env
source /etc/freeipa/master.env
source /etc/os-mongodb/os-mongodb.env

COMPONENT_NAMESPACE="${OPENSTACK_COMPONENT}"







KUBE_COMPONENENT=namespace
namespace=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.yaml

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
################################################################################
cp -f ${TEMPLATE_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.template.yaml $namespace

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: OS_DISTRO"
################################################################################
sed -i "s/{{OS_DISTRO}}/${OS_DISTRO}/" $namespace
sed -i "s/{{OS_RELEASE}}/${OS_RELEASE}/" $namespace
sed -i "s/{{OPENSTACK_COMPONENT}}/${OPENSTACK_COMPONENT}/" $namespace
sed -i "s/{{OPENSTACK_SUBCOMPONENT}}/${OPENSTACK_SUBCOMPONENT}/" $namespace
sed -i "s/{{OS_DOMAIN}}/${OS_DOMAIN}/" $namespace




#
# KUBE_COMPONENENT=volume
# KUBE_SUBCOMPONENENT=definition
# volume_definition=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}_${KUBE_SUBCOMPONENENT}.yaml
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
# ################################################################################
# cp -f ${TEMPLATE_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}_${KUBE_SUBCOMPONENENT}.template.yaml $volume_definition
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: OS_DISTRO"
# ################################################################################
# sed -i "s/{{OPENSTACK_COMPONENT}}/${OPENSTACK_COMPONENT}/" $volume_definition
# sed -i "s,{{OS_DATABASE_MONGODB_DIR}},${OS_DATABASE_MONGODB_DIR}," $volume_definition
#
#
#
#
# KUBE_COMPONENENT=volume
# KUBE_SUBCOMPONENENT=claim
# volume_claim=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}_${KUBE_SUBCOMPONENENT}.yaml
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
# ################################################################################
# cp -f ${TEMPLATE_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}_${KUBE_SUBCOMPONENENT}.template.yaml $volume_claim
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: OS_DISTRO"
# ################################################################################
# sed -i "s/{{OPENSTACK_COMPONENT}}/${OPENSTACK_COMPONENT}/" $volume_claim
#
#
#
















KUBE_COMPONENENT=daemonset
daemonset=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.yaml

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
################################################################################
cp -f ${TEMPLATE_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.template.yaml $daemonset

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: OS_DISTRO"
################################################################################
sed -i "s/{{OS_DISTRO}}/${OS_DISTRO}/" $daemonset
sed -i "s/{{OS_RELEASE}}/${OS_RELEASE}/" $daemonset
sed -i "s/{{OPENSTACK_COMPONENT}}/${OPENSTACK_COMPONENT}/" $daemonset
sed -i "s/{{OS_DOMAIN}}/${OS_DOMAIN}/" $daemonset
sed -i "s/{{OS_REGISTRY}}/${OS_REGISTRY}/" $daemonset

sed -i "s,{{OS_DATABASE_MONGODB_DIR}},${OS_DATABASE_MONGODB_DIR}," $daemonset



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Init: env_vars"
################################################################################
env_files=${TEMPLATE_DIR}/env_files
env_vars=${OUTPUT_DIR}/env_vars
rm -f $env_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Writing: env_vars file"
################################################################################
while read env_file; do
  grep -v '^#' $env_file | sed '/^$/d' >> $env_vars
done <$env_files

KUBE_COMPONENENT=secrets
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Init: secrets file"
################################################################################
secrets=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.yaml
cat > $secrets <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${OPENSTACK_COMPONENT}
type: Opaque
data:
EOF

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Converting env_vars to secrets and writing to secrets file"
################################################################################
while read env_var; do
  ENV_VAR=$(echo $env_var | awk -F'=' '{print $1}')
  ENV_VAR_VALUE=$(echo $env_var | cut -f 1 -d '=' --complement | sed -e 's/^"//'  -e 's/"$//')
  echo "  $(echo $ENV_VAR | tr "[:upper:]" "[:lower:]" | tr -dc 'a-z0-9' ): $(echo "$ENV_VAR=$ENV_VAR_VALUE" | base64 --wrap=0 )" >> $secrets
done <$env_vars

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining IPA Server to use in serets file"
################################################################################
ENV_VAR=IPA_PORT_80_TCP_ADDR
ENV_VAR_VALUE=${IPA_MASTER_HOSTNAME}.${OS_DOMAIN}
echo "  $(echo $ENV_VAR | tr "[:upper:]" "[:lower:]" | tr -dc 'a-z0-9' ): $(echo "$ENV_VAR=$ENV_VAR_VALUE" | base64 --wrap=0 )" >> $secrets





KUBE_COMPONENENT=service
service=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.yaml

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
################################################################################
cp -f ${TEMPLATE_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.template.yaml $service

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Component"
################################################################################
sed -i "s/{{OPENSTACK_COMPONENT}}/${OPENSTACK_COMPONENT}/" $service







################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensureing Data Dir Exists"
################################################################################
mkdir -p ${OS_DATABASE_MONGODB_DIR}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring permissions are correct"
################################################################################
chcon -t svirt_sandbox_file_t ${OS_DATABASE_MONGODB_DIR} || true
