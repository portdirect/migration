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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Cleaning Up any old container"
################################################################################
docker stop foreman-master || true
docker rm foreman-master || true


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching Foreman Container"
################################################################################
cat /etc/os-container.env > /var/lib/harbor/foreman/foreman.env
/usr/bin/docker run -p 444:443 -d -t \
  --name foreman-master \
  --hostname foreman.${OS_DOMAIN} \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v /etc/httpd \
  -v /var/lib/harbor/foreman/foreman.env:/etc/os-config/openstack.env:ro \
  -v /var/lib/harbor/foreman/pod:/var/pod:rw \
  -v /var/lib/harbor/foreman/ssh:/usr/share/foreman-proxy/.ssh/:rw \
  -v /var/lib/harbor/foreman/dynflow:/var/lib/foreman-proxy/dynflow/:rw \
  port/foreman-master:latest /sbin/init


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Starting haproxy to route to kube-endpoint"
################################################################################
FOREMAN_MASTER_IP="$(docker inspect --format '{{.NetworkSettings.IPAddress}}' foreman-master)"
sed -i "s/{{APPLICATION_IP}}/${FOREMAN_MASTER_IP}/" /etc/haproxy/haproxy.cfg
haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: monitoring docker logs"
################################################################################
docker logs -f foreman-master


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Stopping haproxy"
################################################################################
kill $(cat /var/run/haproxy.pid)


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Stopping docker image"
################################################################################
docker stop foreman-master || true
