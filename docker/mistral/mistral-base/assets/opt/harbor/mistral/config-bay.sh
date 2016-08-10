#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=bay
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${DEFAULT_REGION:="HarborOS"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg DEFAULT_REGION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
#
# From mistral
#

# Location of template to build a k8s cluster on atomic. (string value)
# Deprecated group/name - [bay_heat]/template_path
crudini --set $cfg bay k8s_atomic_template_path "/opt/mistral-templates/kubernetes/kubecluster.yaml"

# Location of template to build a k8s cluster on CoreOS. (string value)
crudini --set $cfg bay k8s_coreos_template_path = "/opt/mistral-templates/kubernetes/kubecluster-coreos.yaml"

# Url for etcd public discovery endpoint. (string value)
crudini --set $cfg bay etcd_discovery_service_endpoint_format "http://discovery.etcd.io/new?size=%(size)d"

# Location of template to build a swarm cluster on atomic. (string value)
crudini --set $cfg bay swarm_atomic_template_path "/opt/mistral-templates/swarm/swarmcluster.yaml"

# Location of template to build a Mesos cluster on Ubuntu. (string value)
crudini --set $cfg bay mesos_ubuntu_template_path "/opt/mistral-templates/mesos/mesoscluster.yaml"

# Enabled bay definition entry points. (list value)
#enabled_definitions = mistral_vm_atomic_k8s,mistral_vm_coreos_k8s,mistral_vm_atomic_swarm,mistral_vm_ubuntu_mesos



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Adding IPA CA Cirt to templates"
################################################################################
find /opt/mistral-templates -type f -exec bash -c 'sed -i "s,{{IPA_CA_CRT}},$(cat /etc/pki/tls/certs/ca-bundle.crt | base64 --wrap 0)", "$0"' {} \;
chown -R mistral /opt/mistral-templates
