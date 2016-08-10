#!/bin/bash

OPENSTACK_COMPONENT=os-glusterfs
OPENSTACK_SUBCOMPONENT=glusterfs






TEMPLATE_DIR=/etc/${OPENSTACK_COMPONENT}/kube
OUTPUT_DIR=/etc/${OPENSTACK_COMPONENT}/kube

source /etc/os-common/common.env
source /etc/kubernetes/kubernetes.env
source /etc/${OPENSTACK_COMPONENT}/${OPENSTACK_COMPONENT}.env

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

sed -i "s/{{GLUSTER_VG}}/${GLUSTER_VG}/" $daemonset



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
  name: ${OPENSTACK_COMPONENT}-secret
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
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Init: $KUBE_COMPONENENT file"
################################################################################
service=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.yaml
cat > $service <<EOF
kind: "Service"
apiVersion: "v1"
metadata:
  name: "${OPENSTACK_COMPONENT}"
spec:
  ports:
    - port: 1
EOF



GLUSTER_NODES=$(kubectl get nodes --selector=glusterfs=true --no-headers| awk -F ' ' '{print $1}' | awk -F '.' '{print $1}')
GLUSTER_DOMAIN=os-glusterfs.skydns.local

KUBE_COMPONENENT=endpoints
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Init: $KUBE_COMPONENENT file"
################################################################################
endpoints=${OUTPUT_DIR}/${OPENSTACK_COMPONENT}_${KUBE_COMPONENENT}.yaml
cat > $endpoints <<EOF
kind: "Endpoints"
apiVersion: "v1"
metadata:
  name: "${OPENSTACK_COMPONENT}"
subsets:
EOF
while read -r GLUSTER_NODE; do
  GLUSTER_IP=$(ping -c 1 ${GLUSTER_NODE}.${GLUSTER_DOMAIN} | gawk -F '[()]' '/PING/{print $2}')
  # if [[ ! $GLUSTER_IP ]]; then
  #   GLUSTER_IP=$(ping -c 1 ${GLUSTER_NODE} | gawk -F '[()]' '/PING/{print $2}')
  # fi
  echo " - addresses:" >> $endpoints
  echo "      - ip: \"${GLUSTER_IP}\"" >> $endpoints
  echo "   ports:" >> $endpoints
  echo "      - port: 1" >> $endpoints
done <<< "${GLUSTER_NODES}"


(
echo $daemonset
cat $daemonset
echo $secrets
cat $secrets
echo $service
cat $service
echo $endpoints
cat $endpoints
)
