#!/bin/bash

OPENSTACK_COMPONENT=os-heat
OPENSTACK_SUBCOMPONENT=api

source /etc/os-common/common.env
source /etc/kubernetes/kubernetes.env
source /etc/freeipa/credentials-client-provisioning.env
source /etc/freeipa/master.env
source /etc/$OPENSTACK_COMPONENT/$OPENSTACK_COMPONENT.env


source /etc/etcd/etcd.env
ETCD_IP=$(ip -f inet -o addr show $ETCD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
ETCD_PORT=4001




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Status"
################################################################################
STATUS=$(etcdctl get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/status)
if [ "$STATUS" != "DOWN" ]
then
  echo "Service is not marked as DOWN in etcd at /${OS_DISTRO}/${OPENSTACK_COMPONENT}/status, exiting."
  exit 1
fi

PRIMED=$(etcdctl get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed)
if [ "$PRIMED" != "TRUE" ]
then
  echo "Service is not marked as TRUE in etcd at /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed, exiting."
  exit 1
fi


TEMPLATE_DIR=/etc/$OPENSTACK_COMPONENT/kube
OUTPUT_DIR=/etc/$OPENSTACK_COMPONENT/kube









KUBE_COMPONENENT=replicationcontroller
replicationcontroller=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}-${OPENSTACK_SUBCOMPONENT}_${KUBE_COMPONENENT}.yaml

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
################################################################################
cp -f ${TEMPLATE_DIR}/${OPENSTACK_COMPONENT}-${OPENSTACK_SUBCOMPONENT}_${KUBE_COMPONENENT}.template.yaml $replicationcontroller

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: OS_DISTRO"
################################################################################
sed -i "s/{{OS_DISTRO}}/${OS_DISTRO}/" $replicationcontroller
sed -i "s/{{OS_RELEASE}}/${OS_RELEASE}/" $replicationcontroller
sed -i "s/{{OPENSTACK_COMPONENT}}/${OPENSTACK_COMPONENT}/" $replicationcontroller
sed -i "s/{{OPENSTACK_SUBCOMPONENT}}/${OPENSTACK_SUBCOMPONENT}/" $replicationcontroller
sed -i "s/{{OS_DOMAIN}}/${OS_DOMAIN}/" $replicationcontroller
sed -i "s/{{OS_REGISTRY}}/${OS_REGISTRY}/" $replicationcontroller










KUBE_COMPONENENT=secrets
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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Init: secrets file"
################################################################################
secrets=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.yaml


cat > $secrets <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${OPENSTACK_COMPONENT}-${OPENSTACK_SUBCOMPONENT}-secret
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

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining ETCD endpoint to use in serets file"
################################################################################
ENV_VAR=ETCDCTL_ENDPOINT
ENV_VAR_VALUE=${ETCD_IP}:${ETCD_PORT},
echo "  $(echo $ENV_VAR | tr "[:upper:]" "[:lower:]" | tr -dc 'a-z0-9' ): $(echo "$ENV_VAR=$ENV_VAR_VALUE" | base64 --wrap=0 )" >> $secrets










KUBE_COMPONENENT=service
service=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}-${OPENSTACK_SUBCOMPONENT}_${KUBE_COMPONENENT}.yaml

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Initialising Template"
################################################################################
cp -f ${TEMPLATE_DIR}/${OPENSTACK_COMPONENT}-${OPENSTACK_SUBCOMPONENT}_${KUBE_COMPONENENT}.template.yaml $service

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring: Component"
################################################################################
sed -i "s/{{OPENSTACK_COMPONENT}}/${OPENSTACK_COMPONENT}/" $service
sed -i "s/{{OPENSTACK_SUBCOMPONENT}}/${OPENSTACK_SUBCOMPONENT}/" $service
