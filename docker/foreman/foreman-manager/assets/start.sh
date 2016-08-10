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



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars ETCDCTL_ENDPOINT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing database"
################################################################################
/usr/bin/create-db.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Kubeconfig"
################################################################################
/usr/bin/kubeconfig-helper.sh


kubectl_helper () {
  CMD=$@
  SVC_AUTH_ROOT_LOCAL_CONTAINER=/etc/harbor/auth
  kubectl --kubeconfig="${SVC_AUTH_ROOT_LOCAL_CONTAINER}/kubeconfig.yaml" --server="https://kubernetes.${OS_DOMAIN}" ${CMD}
}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: launching Foreman Server"
################################################################################
docker pull port/foreman-master:latest
cat /opt/harbor/foreman/master.yaml > /tmp/master.yaml
sed -i "s,{{OS_DOMAIN}},${OS_DOMAIN}," /tmp/master.yaml
sed -i "s,{{IPA_USER_ADMIN_USER}},$( printf IPA_USER_ADMIN_USER=${IPA_USER_ADMIN_USER} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{IPA_USER_ADMIN_PASSWORD}},$( printf IPA_USER_ADMIN_PASSWORD=${IPA_USER_ADMIN_PASSWORD} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{IPA_HOST_ADMIN_USER}},$( printf IPA_HOST_ADMIN_USER=${IPA_HOST_ADMIN_USER} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{IPA_HOST_ADMIN_PASSWORD}},$( printf IPA_HOST_ADMIN_PASSWORD=${IPA_HOST_ADMIN_PASSWORD} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{MARIADB_DATABASE}},$( printf MARIADB_DATABASE=${MARIADB_DATABASE} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{MARIADB_PASSWORD}},$( printf MARIADB_PASSWORD=${MARIADB_PASSWORD} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{MARIADB_USER}},$( printf MARIADB_USER=${MARIADB_USER} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_DB_NAME}},$( printf FOREMAN_DB_NAME=${FOREMAN_DB_NAME} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_DB_USER}},$( printf FOREMAN_DB_USER=${FOREMAN_DB_USER} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_DB_PASSWORD}},$( printf FOREMAN_DB_PASSWORD=${FOREMAN_DB_PASSWORD} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_OAUTH_KEY}},$( printf FOREMAN_OAUTH_KEY=${FOREMAN_OAUTH_KEY} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_OAUTH_SECRET}},$( printf FOREMAN_OAUTH_SECRET=${FOREMAN_OAUTH_SECRET} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_SMTP_HOST}},$( printf FOREMAN_SMTP_HOST=${FOREMAN_SMTP_HOST} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_SMTP_PORT}},$( printf FOREMAN_SMTP_PORT=${FOREMAN_SMTP_PORT} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_SMTP_USER}},$( printf FOREMAN_SMTP_USER=${FOREMAN_SMTP_USER} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_SMTP_PASS}},$( printf FOREMAN_SMTP_PASS=${FOREMAN_SMTP_PASS} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_DEFAULT_FROM_EMAIL}},$( printf FOREMAN_DEFAULT_FROM_EMAIL=${FOREMAN_DEFAULT_FROM_EMAIL} | base64 --wrap=0 )," /tmp/master.yaml
sed -i "s,{{FOREMAN_DEFAULT_ADMIN_EMAIL}},$( printf FOREMAN_DEFAULT_ADMIN_EMAIL=${FOREMAN_DEFAULT_ADMIN_EMAIL} | base64 --wrap=0 )," /tmp/master.yaml
kubectl_helper delete -f /tmp/master.yaml || true
kubectl_helper create -f /tmp/master.yaml


# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: launching Foreman Proxies"
# ################################################################################
# docker pull port/foreman-proxy:latest
# for BRIDGE_DEVICE in br0 br1 br2; do
#   cat /opt/harbor/foreman/proxy.yaml > /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{OS_DOMAIN}},${OS_DOMAIN}," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{PROXY_BRIDGE}},${BRIDGE_DEVICE}," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{FOREMAN_OAUTH_SECRET}},$( printf FOREMAN_OAUTH_SECRET=${FOREMAN_OAUTH_SECRET} | base64 --wrap=0 )," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{FOREMAN_OAUTH_KEY}},$( printf FOREMAN_OAUTH_KEY=${FOREMAN_OAUTH_KEY} | base64 --wrap=0 )," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{IPA_USER_ADMIN_USER}},$( printf IPA_USER_ADMIN_USER=${IPA_USER_ADMIN_USER} | base64 --wrap=0 )," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{IPA_USER_ADMIN_PASSWORD}},$( printf IPA_USER_ADMIN_PASSWORD=${IPA_USER_ADMIN_PASSWORD} | base64 --wrap=0 )," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{IPA_HOST_ADMIN_USER}},$( printf IPA_HOST_ADMIN_USER=${IPA_HOST_ADMIN_USER} | base64 --wrap=0 )," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   sed -i "s,{{IPA_HOST_ADMIN_PASSWORD}},$( printf IPA_HOST_ADMIN_PASSWORD=${IPA_HOST_ADMIN_PASSWORD} | base64 --wrap=0 )," /tmp/proxy-${BRIDGE_DEVICE}.yaml
#   kubectl_helper delete -f /tmp/proxy-${BRIDGE_DEVICE}.yaml || true
#   kubectl_helper create -f /tmp/proxy-${BRIDGE_DEVICE}.yaml
# done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE



# for BRIDGE_DEVICE in br0 br1 br2; do
#   # do something
#   BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
#   IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2"."$3".10"}')
#   docker run -d -t \
#   --name foreman-proxy-${BRIDGE_DEVICE} \
#   --hostname foreman-proxy-${BRIDGE_DEVICE}.port.direct \
#   --privileged \
#   -v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
#   -v /var/lib/harbor/foreman/pod:/var/pod:rw \
#   -v /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}/tftpboot:/var/lib/tftpboot:rw \
#   -v /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}/puppet:/var/lib/puppet/ssl:rw \
#   port/foreman-proxy:latest /sbin/init
#   sudo pipework ${BRIDGE_DEVICE} -i ${BRIDGE_DEVICE} -l dhcp_${BRIDGE_DEVICE} foreman-proxy-${BRIDGE_DEVICE} ${IP}/16
#   docker logs -f foreman-proxy-${BRIDGE_DEVICE}
# done
