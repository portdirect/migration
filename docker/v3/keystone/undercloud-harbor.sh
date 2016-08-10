#!/bin/bash

NODE_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
MASTER_IP=$NODE_IP
echo "${NODE_IP} $(hostname -s).novalocal $(hostname -s)" >> /etc/hosts
hostnamectl set-hostname $(hostname -s).novalocal



sed -i "s/MountFlags=slave/MountFlags=shared/" /etc/systemd/system/docker.service

systemctl daemon-reload
systemctl restart docker
systemctl status docker

mkdir -p /etc/harbor
cat > /etc/harbor/kube.env <<EOF
KUBE_DEV=eth0
MASTER_IP=${MASTER_IP}
ROLE=master
EOF









cat > /usr/local/bin/openstack <<EOF
#!/bin/bash
CONTROLLER_IP=\$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
docker run -t --rm \
-e EXPOSED_IP=\${CONTROLLER_IP} \
-e OS_REGION_NAME="RegionOne" \
-e OS_PROJECT_NAME="admin" \
-e OS_DOMAIN_NAME="default" \
-e OS_IDENTITY_API_VERSION="3" \
-e OS_PASSWORD="password" \
-e OS_AUTH_URL="http://\${CONTROLLER_IP}:35357/v3" \
-e OS_USERNAME="admin" \
-e OS_TENANT_NAME="admin" \
docker.io/port/undercloud-openstackclient openstack "\$@"
EOF
chmod +x /usr/local/bin/openstack


cat > /usr/local/bin/nova <<EOF
#!/bin/bash
CONTROLLER_IP=\$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
docker run -t --rm \
-e EXPOSED_IP=\${CONTROLLER_IP} \
-e OS_REGION_NAME="RegionOne" \
-e OS_PROJECT_NAME="admin" \
-e OS_IDENTITY_API_VERSION="3" \
-e OS_PASSWORD="password" \
-e OS_AUTH_URL="http://\${CONTROLLER_IP}:35357/v3" \
-e OS_USERNAME="admin" \
docker.io/port/undercloud-novaclient nova "\$@"
EOF
chmod +x /usr/local/bin/nova



cat > /usr/local/bin/cinder <<EOF
#!/bin/bash
CONTROLLER_IP=\$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
docker run -t --rm \
-e EXPOSED_IP=\${CONTROLLER_IP} \
-e OS_REGION_NAME="RegionOne" \
-e OS_PROJECT_NAME="admin" \
-e OS_PROJECT_DOMAIN_NAME="Default" \
-e OS_USER_DOMAIN_NAME="Default" \
-e OS_IDENTITY_API_VERSION="3" \
-e OS_PASSWORD="password" \
-e OS_AUTH_URL="http://\${CONTROLLER_IP}:35357/v3" \
-e OS_USERNAME="admin" \
docker.io/port/undercloud-cinderclient cinder "\$@"
EOF
chmod +x /usr/local/bin/cinder


cat > /usr/local/bin/docker-to-glance <<EOF
#!/bin/bash
docker pull "\$@"
docker tag "\$@" "\$@"
CONTROLLER_IP=\$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
docker run -t --rm \
-e EXPOSED_IP=\${CONTROLLER_IP} \
-e OS_REGION_NAME="RegionOne" \
-e OS_PROJECT_NAME="admin" \
-e OS_DOMAIN_NAME="default" \
-e OS_IDENTITY_API_VERSION="3" \
-e OS_PASSWORD="password" \
-e OS_AUTH_URL="http://\${CONTROLLER_IP}:35357/v3" \
-e OS_USERNAME="admin" \
-e OS_TENANT_NAME="admin" \
-v /var/run/docker.sock:/var/run/docker.sock:rw \
docker.io/port/undercloud-openstackclient /bin/sh -c "docker save "\$@" | openstack image create "\$@" --public --container-format docker --disk-format raw"
EOF
chmod +x /usr/local/bin/docker-to-glance


cat > /usr/local/bin/neutron <<EOF
#!/bin/bash
CONTROLLER_IP=\$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
docker run -t --rm \
-e EXPOSED_IP=\${CONTROLLER_IP} \
-e OS_REGION_NAME="RegionOne" \
-e OS_PROJECT_NAME="admin" \
-e OS_DOMAIN_NAME="default" \
-e OS_IDENTITY_API_VERSION="3" \
-e OS_PASSWORD="password" \
-e OS_AUTH_URL="http://\${CONTROLLER_IP}:35357/v3" \
-e OS_USERNAME="admin" \
-e OS_TENANT_NAME="admin" \
docker.io/port/undercloud-neutronclient neutron "\$@"
EOF
chmod +x /usr/local/bin/neutron


cat > /usr/local/bin/swarm <<EOF
#!/bin/bash
exec docker -H unix:///var/run/swarm/docker.sock "\$@"
EOF
chmod +x /usr/local/bin/swarm


cat > /usr/local/bin/undercloud-bootstrap <<EOF
#!/bin/bash
CONTROLLER_IP=\$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
docker run -t --rm \
-e CONTROLLER_IP=\${CONTROLLER_IP} \
-e KEYSTONE_SERVICE_HOST=\${CONTROLLER_IP} \
-e OS_REGION_NAME="RegionOne" \
-e OS_PROJECT_NAME="admin" \
-e OS_DOMAIN_NAME="default" \
-e OS_IDENTITY_API_VERSION="3" \
-e OS_PASSWORD="password" \
-e OS_AUTH_URL="http://\${CONTROLLER_IP}:35357/v3" \
-e OS_USERNAME="admin" \
-e OS_TENANT_NAME="admin" \
docker.io/port/undercloud-openstackclient /undercloud-bootstrap.sh
EOF
chmod +x /usr/local/bin/undercloud-bootstrap





cat > /etc/harbor/network.env <<EOF
PUBLIC_IP_RANGE=10.80.0.0/12
PUBLIC_IP_START=10.80.1.0
PUBLIC_IP_END=10.95.255.254
PUBLIC_GATEWAY=10.80.0.1/12
PUBLIC_DNS=8.8.8.8
PUBLIC_SUBNET_NAME=ext-subnet
PUBLIC_NET_NAME=ext-net
PUBLIC_NET_DEV=br-ex


UPLINK_IP_RANGE=10.64.0.0/16
UPLINK_GATEWAY=10.64.0.1
UPLINK_NET_NAME=kuryr-uplink
UPLINK_ROUTER_NAME=kuryr-uplink


ADMIN_IP_RANGE=10.63.0.0/16
ADMIN_GATEWAY=10.63.0.1
ADMIN_NET_NAME=admin
ADMIN_SUBNET_NAME=admin
ADMIN_ROUTER_NAME=admin


AUTH_IP_RANGE=10.61.0.0/16
KUBE_IP_RANGE=192.168.1.1/16
KUBE_SVC_RANGE=10.10.0.0/24

OS_DOMAIN=local.tld

EXTERNAL_DNS=8.8.8.8
EXTERNAL_DNS_1=8.8.4.4

# The kubelet ip is unused but makes it easier to issue a cert for kube services.
# To make is worse though we call this kubelet, it's used by everything but the
# kubelet. The evolution of the Harbor Platform, created this situation, it is
# our small intestine...
SERVICE_IP_KUBE=10.10.0.1
SERVICE_IP_KUBELET=10.10.0.2
SERVICE_IP_ETCD_KUBE=10.10.0.3
SERVICE_IP_ETCD_NETWORK=10.10.0.4
SERVICE_IP_ETCD_DOCKER=10.10.0.5
SERVICE_IP_SWARM=10.10.0.6
SERVICE_IP_DNS_KUBE=10.10.0.7
SERVICE_IP_DNS_FREEIPA=10.10.0.8


EOF

# PATH=${PATH}:/usr/local/bin
# source /etc/harbor/network.env
# source /etc/harbor/auth.env
#
# IPA_DATA_DIR=/var/lib/harbor/freeipa/master
# mkdir -p ${IPA_DATA_DIR}
# echo "--allow-zone-overlap" > ${IPA_DATA_DIR}/ipa-server-install-options
# echo "--setup-dns" >> ${IPA_DATA_DIR}/ipa-server-install-options
# echo "--forwarder=${EXTERNAL_DNS}" >> ${IPA_DATA_DIR}/ipa-server-install-options
# echo "--forwarder=${EXTERNAL_DNS_1}" >> ${IPA_DATA_DIR}/ipa-server-install-options
# for BRIDGE_IP in ${AUTH_IP_RANGE} ${KUBE_IP_RANGE} ${KUBE_SVC_RANGE}; do
#   # do something
#   REVERSE_ZONE=$(echo ${BRIDGE_IP} | awk -F. '{print $3"." $2"."$1".in-addr.arpa."}')
#   echo "--reverse-zone=${REVERSE_ZONE}" >> ${IPA_DATA_DIR}/ipa-server-install-options
# done
# echo "--ds-password=${IPA_DS_PASSWORD}" >> ${IPA_DATA_DIR}/ipa-server-install-options
# echo "--admin-password=${IPA_ADMIN_PASSWORD}" >> ${IPA_DATA_DIR}/ipa-server-install-options
#
#
# docker run -t \
#     --hostname=freeipa-master.${OS_DOMAIN} \
#     --privileged \
#     --name=freeipa-master \
#     -v ${IPA_DATA_DIR}:/data:rw \
#     -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#     --dns=${EXTERNAL_DNS} \
#     -e OS_DOMAIN=${OS_DOMAIN} \
#     docker.io/port/ipa-server:latest exit-on-finished



systemctl start iscsid.socket iscsiuio.socket
systemctl enable iscsid.socket iscsiuio.socket
systemctl restart kubelet
systemctl enable kubelet




export PATH=/usr/local/bin:$PATH
undercloud-bootstrap

docker-to-glance ewindisch/cirros:latest
docker-to-glance docker.io/nginx:latest
kubectl get nodes






source /etc/harbor/network.env
ovs-vsctl --may-exist add-br ${PUBLIC_NET_DEV}
ovs-vsctl --may-exist add-br ${PUBLIC_NET_DEV} -- set bridge ${PUBLIC_NET_DEV} protocols=OpenFlow13
ovs-vsctl set open . external-ids:ovn-bridge-mappings=public:${PUBLIC_NET_DEV}



ip addr add ${PUBLIC_GATEWAY} dev ${PUBLIC_NET_DEV}
ip link set up ${PUBLIC_NET_DEV}
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

source /etc/harbor/network.env
neutron net-create \
--description="Public Network" \
--router:external=True \
--provider:physical_network=public \
--provider:network_type=flat \
"${PUBLIC_NET_NAME}"


source /etc/harbor/network.env
neutron subnet-create  \
--name="${PUBLIC_SUBNET_NAME}" \
--description="Public Subnet" \
--allocation-pool="start=${PUBLIC_IP_START},end=${PUBLIC_IP_END}" \
--disable-dhcp \
--gateway="${PUBLIC_GATEWAY%/*}" \
"${PUBLIC_NET_NAME}" \
"${PUBLIC_IP_RANGE}"


source /etc/harbor/network.env
neutron net-create \
--description="Admin Network" \
"${ADMIN_NET_NAME}"
neutron --debug subnet-create \
--description="Admin Subnet" \
--disable-dhcp \
--name "${ADMIN_SUBNET_NAME}" \
"${ADMIN_NET_NAME}" \
"${ADMIN_IP_RANGE}"

neutron subnetpool-create --default-prefixlen 24 --pool-prefix 192.168.0.0/16 kuryr




source /etc/harbor/network.env

neutron net-create \
--description="Admin Network" \
"${ADMIN_NET_NAME}"
neutron subnet-create \
--description="Admin Subnet" \
--name "${ADMIN_SUBNET_NAME}" \
"${ADMIN_NET_NAME}" \
"${ADMIN_IP_RANGE}"

neutron router-create \
--description "Router for ${ADMIN_NET_NAME}" \
${ADMIN_ROUTER_NAME}
neutron router-gateway-set \
"${ADMIN_ROUTER_NAME}" \
"${PUBLIC_NET_NAME}"
neutron router-interface-add \
"${ADMIN_ROUTER_NAME}" \
"${ADMIN_SUBNET_NAME}"







neutron security-group-create \
--description "security rules to access demo instances" \
"demo"

neutron security-group-rule-create \
--description "Global SSH Access" \
--direction ingress \
--protocol tcp \
--port-range-min 22 \
--port-range-max 22 \
--remote-ip-prefix 0.0.0.0/0 \
"demo"

neutron security-group-rule-create \
--description "Global HTTP Access" \
--direction ingress \
--ethertype IPv4 \
--protocol tcp \
--port-range-min 80 \
--port-range-max 80 \
--remote-ip-prefix 0.0.0.0/0 \
"demo"

neutron security-group-rule-create \
--description "Global HTTPS Access" \
--direction ingress \
--ethertype IPv4 \
--protocol tcp \
--port-range-min 443 \
--port-range-max 443 \
--remote-ip-prefix 0.0.0.0/0 \
"demo"

neutron security-group-rule-create \
--description "Global ICMP Access" \
--direction ingress \
--ethertype IPv4 \
--protocol icmp \
--remote-ip-prefix 0.0.0.0/0 \
"demo"











source /etc/harbor/network.env
neutron router-gateway-set raven-default-router "${PUBLIC_NET_NAME}"








source /etc/harbor/network.env
neutron net-create \
--description="Uplink Network" \
"${UPLINK_NET_NAME}"
UPLINK_NET_ID=230bebb6-665a-49c6-b044-bb94d53741af
docker network create \
--driver=kuryr \
--subnet="${UPLINK_IP_RANGE}" \
--gateway="${UPLINK_GATEWAY}" \
-o neutron.net.uuid="${UPLINK_NET_ID}" \
"${UPLINK_NET_NAME}"





source /etc/harbor/network.env
neutron router-create \
--description "Uplink Router for ${UPLINK_NET_NAME}" \
${UPLINK_ROUTER_NAME}

source /etc/harbor/network.env
neutron router-gateway-set \
"${UPLINK_ROUTER_NAME}" \
"${PUBLIC_NET_NAME}"


UPLINK_NET_ID="$(swarm network inspect ${UPLINK_NET_NAME} --format '{{ .Id }}')"
UPLINK_SUBNET_ID="$(neutron net-show ${UPLINK_NET_ID} -f value -c subnets  | tr -cd '[:print:]' )"
neutron router-interface-add \
"${UPLINK_ROUTER_NAME}" \
"${UPLINK_SUBNET_ID}"
















ADMIN_IP_RANGE=10.63.0.0/16
ADMIN_GATEWAY=10.63.0.1
ADMIN_NET_NAME=admin
ADMIN_ROUTER_NAME=admin
EOF








kubectl run --image=nginx --replicas=2 nginx
kubectl run --image=docker.io/port/base:latest --replicas=1 port-testing -- tail -f /dev/null





















cat > /etc/systemd/system/uplink.service <<EOF
[Unit]
Description=Neutron Uplink Service
Documentation=https://port.direct
After=kubelet.service
Requires=kubelet.service
Wants=network-online.target

[Service]
ExecStartPre=/usr/local/bin/uplink-daemon-start
ExecStart=/usr/local/bin/uplink-daemon-monitor
ExecStop=/usr/local/bin/uplink-daemon-stop
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


cat > /usr/local/bin/uplink-daemon-start <<EOF
#!/bin/sh
set -e
source /etc/harbor/network.env
source /etc/harbor/kube.env
UPLINK_CONTAINER_NAME="uplink-\$(hostname -s).\$(hostname -d)"

docker stop \${UPLINK_CONTAINER_NAME} || true
docker rm -f -v \${UPLINK_CONTAINER_NAME} || true
echo "Creating Uplink Container"
docker create \
      --privileged \
      --cap-add NET_ADMIN \
      --net=bridge \
      --name=\${UPLINK_CONTAINER_NAME} \
      -e PUBLIC_IP_RANGE=\${PUBLIC_IP_RANGE} \
      -e UPLINK_IP_RANGE=\${UPLINK_IP_RANGE} \
      -e UPLINK_GATEWAY=\${UPLINK_GATEWAY} \
      docker.io/port/undercloud-uplink:latest

echo "Connecting Uplink Container To Uplink Network"
docker network connect \
      --alias \${UPLINK_NET_NAME} \
      \${UPLINK_NET_NAME} \
      \${UPLINK_CONTAINER_NAME}

echo "Starting Uplink Container"
docker start \${UPLINK_CONTAINER_NAME}

echo "Adding Routes to uplink network"
UPLINK_HOST_IP="\$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' \${UPLINK_CONTAINER_NAME})"
ip route del \${UPLINK_IP_RANGE} || true
ip route add \${UPLINK_IP_RANGE} via \${UPLINK_HOST_IP}


if [ "\$ROLE" = "master" ]; then
    echo "This is a master node, so we should access the public network via the gateway router"
else
    echo "Adding Routes to public network"
    ip route del \${PUBLIC_IP_RANGE} || true
    ip route add \${PUBLIC_IP_RANGE} via \${UPLINK_HOST_IP}
fi;



EOF
chmod +x /usr/local/bin/uplink-daemon-start

cat > /usr/local/bin/uplink-daemon-monitor <<EOF
#!/bin/sh
UPLINK_CONTAINER_NAME="uplink-\$(hostname -s).\$(hostname -d)"
exec docker wait \${UPLINK_CONTAINER_NAME}
EOF
chmod +x /usr/local/bin/uplink-daemon-monitor

cat > /usr/local/bin/uplink-daemon-stop <<EOF
#!/bin/sh
UPLINK_CONTAINER_NAME="uplink-\$(hostname -s).\$(hostname -d)"
docker stop \${UPLINK_CONTAINER_NAME} || true
docker rm -v -f \${UPLINK_CONTAINER_NAME} || true
EOF
chmod +x /usr/local/bin/uplink-daemon-stop
