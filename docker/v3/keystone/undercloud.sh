#!/bin/bash

NODE_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
MASTER_IP=$NODE_IP
echo "${NODE_IP} $(hostname -s).novalocal $(hostname -s)" >> /etc/hosts
hostnamectl set-hostname $(hostname -s).novalocal

cat > /etc/yum.repos.d/docker.repo <<EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

################################################################################
echo "${OS_DISTRO}: SELINUX"
################################################################################
setenforce 0
cat > /etc/selinux/config <<EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF

################################################################################
echo "${OS_DISTRO}: DOCKER"
################################################################################
yum install -y docker-engine bridge-utils
cat > /etc/systemd/system/docker-storage-setup.service <<EOF
[Unit]
Description=Docker Storage Setup
After=network.target
Before=docker.service
[Service]
Type=oneshot
ExecStart=/usr/bin/docker-storage-setup
EnvironmentFile=-/etc/sysconfig/docker-storage-setup
[Install]
WantedBy=multi-user.target
EOF


cat > /etc/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target

[Service]
Type=notify

ExecStartPre=-/sbin/rmmod vport_geneve
ExecStartPre=-/sbin/rmmod vport_vxlan
ExecStartPre=-/sbin/rmmod openvswitch
ExecStartPre=-/sbin/rmmod gre
ExecStartPre=-/sbin/rmmod vxlan
ExecStartPre=-/sbin/rmmod nf_nat_ipv6
ExecStartPre=-/sbin/rmmod nf_conntrack_ipv6

ExecStartPre=-/sbin/modprobe libcrc32c
ExecStartPre=-/sbin/modprobe nf_conntrack_ipv6
ExecStartPre=-/sbin/modprobe nf_nat_ipv6
ExecStartPre=-/sbin/modprobe gre
ExecStartPre=-/sbin/modprobe openvswitch
ExecStartPre=-/sbin/modprobe vxlan
ExecStartPre=-/sbin/modprobe vport-geneve
ExecStartPre=-/sbin/modprobe vport-vxlan
ExecStartPre=/usr/bin/bash -c 'mkdir -p /usr/lib/docker/plugins/kuryr; echo "http://127.0.0.1:23750" > /usr/lib/docker/plugins/kuryr/kuryr.spec'
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker

ExecStartPre=-/sbin/modprobe overlay

ExecStart=/usr/bin/docker daemon -s overlay -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375 --cluster-advertise=eth0:2375 --cluster-store etcd://${MASTER_IP}:4001
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart docker

################################################################################
echo "${OS_DISTRO}: OVS_KERNEL"
################################################################################
docker pull port/ovs-vswitchd:latest
docker run -d \
--name ovs-installer \
-v /srv \
port/ovs-vswitchd:latest tail -f /dev/null
OVS_RPM_DIR="$(docker inspect --format '{{ range .Mounts }}{{ if eq .Destination "/srv" }}{{ .Source }}{{ end }}{{ end }}' ovs-installer)"
yum install -y ${OVS_RPM_DIR}/x86_64/openvswitch-kmod*.rpm
#yum install -y ${OVS_RPM_DIR}/x86_64/*.rpm ${OVS_RPM_DIR}/noarch/*.rpm
docker stop ovs-installer
docker rm -v ovs-installer
systemctl daemon-reload
systemctl restart docker

cat > /usr/bin/ovs-vsctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovsdb-server-node ovs-vsctl "\$@"
EOF
chmod +x /usr/bin/ovs-vsctl
cat > /usr/bin/ovs-ofctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovsdb-server-node ovs-ofctl "\$@"
EOF
chmod +x /usr/bin/ovs-ofctl


cat > /usr/bin/ovn-nbctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovsdb-server-nb ovn-nbctl "\$@"
EOF
chmod +x /usr/bin/ovn-nbctl
cat > /usr/bin/ovn-sbctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovsdb-server-sb ovn-sbctl "\$@"
EOF
chmod +x /usr/bin/ovn-sbctl




cat > /etc/systemd/system/kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet Service
Documentation=https://docs.docker.com
After=network-online.target cloud-init.service chronyd.service docker.service
Requires=docker.service
Wants=network-online.target

[Service]
ExecStartPre=/usr/local/bin/kubelet-daemon-start
ExecStart=/usr/local/bin/kubelet-daemon-monitor
ExecStop=/usr/local/bin/kubelet-daemon-stop
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


mkdir -p /etc/harbor
cat > /etc/harbor/kube.env <<EOF
KUBE_DEV=eth0
MASTER_IP=${MASTER_IP}
ROLE=master
EOF

cat > /usr/local/bin/kubelet-daemon-start <<EOF
#!/bin/sh
mkdir -p /etc/harbor
touch /etc/harbor/kube.env
touch /etc/harbor/kube-status
touch /etc/harbor/kube_openstack_config

KUBELET_IMAGE=docker.io/port/system-kubelet:latest
docker pull \${KUBELET_IMAGE} || true
docker rm -v -f kubelet || true
exec docker run \
--name kubelet \
-d \
--restart=always \
--volume=/:/rootfs:ro \
--volume=/dev/net:/dev/net:rw \
--volume=/var/run/netns:/var/run/netns:rw \
--volume=/var/run/openvswitch:/var/run/openvswitch:rw \
--volume=/sys:/sys:ro \
--volume=/var/lib/docker/:/var/lib/docker:rw \
--volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
--volume=/var/run:/var/run:rw \
--volume=/etc/harbor/kube.env:/etc/harbor/kube.env:ro \
--volume=/etc/harbor/kube-status:/etc/harbor/kube-status:rw \
--volume=/etc/harbor/kube_openstack_config:/etc/harbor/kube_openstack_config:rw \
--net=host \
--privileged=true \
--pid=host \
\${KUBELET_IMAGE} /kubelet
EOF
chmod +x /usr/local/bin/kubelet-daemon-start

cat > /usr/local/bin/kubelet-daemon-monitor <<EOF
#!/bin/sh
exec docker wait kubelet
EOF
chmod +x /usr/local/bin/kubelet-daemon-monitor

cat > /usr/local/bin/kubelet-daemon-stop <<EOF
#!/bin/sh
docker stop kubelet || true
#(docker ps | awk '{ if (\$NF ~ "^k8s_") print \$1 }' | xargs -l1 docker stop) || true
docker rm -v -f kubelet || true
EOF
chmod +x /usr/local/bin/kubelet-daemon-stop




cat > /usr/bin/kubectl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /:/rootfs:ro \
port/undercloud-kubectl:latest /usr/bin/kubectl "\$@"
EOF
chmod +x /usr/bin/kubectl


cat > /usr/bin/openstack <<EOF
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
chmod +x /usr/bin/openstack


cat > /usr/bin/nova <<EOF
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
chmod +x /usr/bin/nova


cat > /usr/bin/docker-to-glance <<EOF
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
chmod +x /usr/bin/docker-to-glance


cat > /usr/bin/neutron <<EOF
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
chmod +x /usr/bin/neutron


cat > /usr/bin/swarm <<EOF
#!/bin/bash
exec docker -H unix:///var/run/swarm/docker.sock "\$@"
EOF
chmod +x /usr/bin/swarm


cat > /usr/bin/undercloud-bootstrap <<EOF
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
chmod +x /usr/bin/undercloud-bootstrap






systemctl restart kubelet



/usr/bin/undercloud-bootstrap
/usr/bin/docker-to-glance ewindisch/cirros:latest
/usr/bin/docker-to-glance docker.io/nginx:latest
kubectl get nodes


export PATH=/usr/local/bin:$PATH

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
EOF


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
--description="Uplink Network" \
"${UPLINK_NET_NAME}"
UPLINK_NET_ID=7a28c9cf-9a88-49a4-9876-15a16f2d3837
docker network create \
--driver=kuryr \
--subnet="${UPLINK_IP_RANGE}" \
--gateway="${UPLINK_GATEWAY}" \
-o neutron.net.uuid="${UPLINK_NET_ID}" \
"hey${UPLINK_NET_NAME}"

swarm network rm ${UPLINK_NET_NAME} || true
swarm network create \
--driver=kuryr \
--ipam-driver=kuryr \
--subnet="${UPLINK_IP_RANGE}" \
--ip-range="${UPLINK_IP_RANGE}" \
--gateway="${UPLINK_GATEWAY}" \
-o neutron.pool.name="${UPLINK_NET_NAME}" \
--ipam-opt=neutron.pool.name="${UPLINK_NET_NAME}" \
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











neutron net-create int-net
neutron subnet-create int-net --name int-subnet 203.0.115.0/24

neutron router-create int-gateway
neutron router-gateway-set int-gateway ext-net
neutron router-interface-add int-gateway int-subnet



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
demo

neutron security-group-rule-create \
--description "Global HTTPS Access" \
--direction ingress \
--ethertype IPv4 \
--protocol tcp \
--port-range-min 443 \
--port-range-max 443 \
--remote-ip-prefix 0.0.0.0/0 \
demo

neutron security-group-rule-create \
--description "Global ICMP Access" \
--direction ingress \
--ethertype IPv4 \
--protocol icmp \
--remote-ip-prefix 0.0.0.0/0 \
demo


















neutron router-gateway-set raven-default-router ext-net












cat > /etc/systemd/system/uplink.service <<EOF
[Unit]
Description=Neutron Uplink Service
Documentation=https://port.direct
After=kubelet.service swarm.service
Requires=kubelet.service swarm.service
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


if [ "$ROLE" = "master" ]; then
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
