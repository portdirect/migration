#!/usr/bin/env bash

set -e

# Persistent journal by default, because Atomic doesn't have syslog
echo 'Storage=persistent' >> /etc/systemd/journald.conf

# Disable iscsid on host
systemctl disable iscsid.socket iscsiuio.socket iscsid.service


# See: https://bugzilla.redhat.com/show_bug.cgi?id=1051816
KEEPLANG=en_US
find /usr/share/locale -mindepth  1 -maxdepth 1 -type d -not -name "${KEEPLANG}" -exec rm -rf {} +
localedef --list-archive | grep -a -v ^"${KEEPLANG}" | xargs localedef --delete-from-archive
mv -f /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
build-locale-archive


# Set OS Release Info
cat > /etc/os-release <<EOF
NAME="Harbor Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel centos"
VERSION_ID="7"
PRETTY_NAME="Harbor Linux"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://harboros.net"
BUG_REPORT_URL="https://harboros.net/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"
EOF


# Look I know how horrible this is, but at the moment its the only way
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


# As /usr will be mounted read only it's easier to setup docker to use kuryr here.
mkdir -p /usr/lib/docker/plugins/kuryr
echo "http://127.0.0.1:23750" > /usr/lib/docker/plugins/kuryr/kuryr.spec


# As /usr will be mounted read only it's easier to setup docker to use kuryr here.
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

ExecStartPre=-/sbin/modprobe overlay

ExecStart=/usr/bin/docker-daemon
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

mkdir -p /etc/harbor
cat > /etc/harbor/docker.env <<EOF
DOCKER_DEV=eth0
DOCKER_PORT=2375
EOF

cat > /usr/bin/docker-daemon <<EOF
#!/bin/sh
set -e
source /etc/harbor/docker.env
DOCKER_IP=\$(ip -f inet -o addr show \${DOCKER_DEV}|cut -d\  -f 7 | cut -d/ -f 1)
exec docker daemon \\
     -s overlay \\
     -H unix:///var/run/docker.sock \\
     -H tcp://\${DOCKER_IP}:\${DOCKER_PORT} \\
     --cluster-advertise=\${DOCKER_DEV}:\${DOCKER_PORT} \\
     --cluster-store etcd://127.0.0.1:4001
EOF
chmod +x /usr/bin/docker-daemon



# Basic OVS and OVN helper scripts
cat > /usr/bin/ovs-vsctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovs:latest ovs-vsctl "\$@"
EOF
chmod +x /usr/bin/ovs-vsctl

cat > /usr/bin/ovs-ofctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovs:latest ovs-ofctl "\$@"
EOF
chmod +x /usr/bin/ovs-ofctl


cat > /usr/bin/ovn-nbctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovn:latest ovn-nbctl "\$@"
EOF
chmod +x /usr/bin/ovn-nbctl
cat > /usr/bin/ovn-sbctl <<EOF
#!/bin/sh
exec docker run -t --rm \
--net=host \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
docker.io/port/ovn:latest ovn-sbctl "\$@"
EOF
chmod +x /usr/bin/ovn-sbctl


# The Kubelet service and associcated functions
cat > /etc/systemd/system/kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet Service
Documentation=http://harboros.net
After=network-online.target cloud-init.service chronyd.service docker.service
Requires=docker.service
Wants=network-online.target

[Service]
ExecStartPre=/usr/bin/kubelet-daemon-start
ExecStart=/usr/bin/kubelet-daemon-monitor
ExecStop=/usr/bin/kubelet-daemon-stop
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /usr/bin
cat > /usr/bin/kubelet-daemon-start <<EOF
#!/bin/sh
mkdir -p /etc/harbor
touch /etc/harbor/kube.env
touch /etc/harbor/kube-status
touch /etc/harbor/kube_openstack_config

KUBELET_IMAGE=docker.io/port/system-kubelet:latest
docker pull \${KUBELET_IMAGE} || true
docker rm -v -f kubelet || true
exec docker run \\
--name kubelet \\
-d \\
--restart=always \\
--volume=/:/rootfs:ro \\
--volume=/dev/net:/dev/net:rw \\
--volume=/var/run/netns:/var/run/netns:rw \\
--volume=/var/run/openvswitch:/var/run/openvswitch:rw \\
--volume=/sys:/sys:ro \\
--volume=/var/lib/docker/:/var/lib/docker:rw \\
--volume=/var/lib/kubelet/:/var/lib/kubelet:rw \\
--volume=/var/run:/var/run:rw \\
--volume=/etc/harbor/kube.env:/etc/harbor/kube.env:ro \\
--volume=/etc/harbor/kube-status:/etc/harbor/kube-status:rw \\
--volume=/etc/harbor/kube_openstack_config:/etc/harbor/kube_openstack_config:rw \\
--net=host \\
--privileged=true \\
--pid=host \\
\${KUBELET_IMAGE} /kubelet
EOF
chmod +x /usr/bin/kubelet-daemon-start

cat > /usr/bin/kubelet-daemon-monitor <<EOF
#!/bin/sh
exec docker wait kubelet
EOF
chmod +x /usr/bin/kubelet-daemon-monitor

cat > /usr/bin/kubelet-daemon-stop <<EOF
#!/bin/sh
docker stop kubelet || true
#(docker ps | awk '{ if (\$NF ~ "^k8s_") print \$1 }' | xargs -l1 docker stop) || true
docker rm -v -f kubelet || true
EOF
chmod +x /usr/bin/kubelet-daemon-stop

cat > /usr/bin/kubectl <<EOF
#!/bin/sh
exec docker run -t --rm \\
--net=host \\
-v /:/rootfs:ro \\
port/undercloud-kubectl:latest /usr/bin/kubectl "\$@"
EOF
chmod +x /usr/bin/kubectl
