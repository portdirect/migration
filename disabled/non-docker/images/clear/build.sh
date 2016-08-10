#!/bin/bash

yum install -y wget libguestfs-tools


IMAGE=clearlinux
VERSION=2900
mkdir -p /tmp/${IMAGE}
cd /tmp/${IMAGE}
wget https://download.clearlinux.org/current/clear-${VERSION}-cloud.qcow -O ${IMAGE}.qcow2
#wget https://download.clearlinux.org/current/clear-${VERSION}-containers.img.xz -O ${IMAGE}-containers.img.xz

cp ../${IMAGE}.qcow2 ${IMAGE}.qcow2



MOUNT="/tmp/${IMAGE}/mnt"
mkdir -p ${MOUNT}
guestmount --rw  -a ${IMAGE}.qcow2 -m /dev/sda2 ${MOUNT}



cat > /etc/yum.repos.d/clear.repo << EOF
[clear]
name=clear
baseurl=https://download.clearlinux.org/current/x86_64/os/
enabled=0
gpgcheck=0
priority=1
EOF

yum -y --nogpg --installroot=${MOUNT} --disablerepo='*' --enablerepo=clear install curl which iputils docker docker-py docker-py-python iptables ca-certs bridge-utils

yum -y --nogpg --installroot=${MOUNT} --disablerepo='*' --enablerepo=clear install llvm kvmtool lxc tar xz rkt linux-container openssl rpm #go

wget https://download.clearlinux.org/current/clear-2900-containers.img.xz -O ../clear-2900-containers.img.xz

cp ../clear-2900-containers.img.xz ${MOUNT}/usr/lib/docker/clear-2900-containers.img.xz



curl -L  https://github.com/coreos/etcd/releases/download/v2.1.3/etcd-v2.1.3-linux-amd64.tar.gz -o etcd-v2.1.3-linux-amd64.tar.gz && \
tar xzvf etcd-v2.1.3-linux-amd64.tar.gz && \
cp etcd-v2.1.3-linux-amd64/etcd ${MOUNT}/bin/etcd && \
cp etcd-v2.1.3-linux-amd64/etcdctl ${MOUNT}/bin/etcdctl

wget https://github.com/coreos/flannel/releases/download/v0.5.3/flannel-0.5.3-linux-amd64.tar.gz -O flannel-0.5.3-linux-amd64.tar.gz && \
tar xzvf flannel-0.5.3-linux-amd64.tar.gz && \
cp flannel-0.5.3/flanneld ${MOUNT}/bin/flanneld

#ls ${MOUNT}/usr/lib/kernel/vmlinux.container
# Install latest docker
#rm -rf ${MOUNT}/usr/bin/docker
#curl -L https://master.dockerproject.org/linux/amd64/docker > ${MOUNT}/usr/bin/docker




curl -L https://github.com/kubernetes/kubernetes/releases/download/v1.0.5/kubernetes.tar.gz -o kubernetes.tar.gz
tar xzvf kubernetes.tar.gz
#cp ./kubernetes/platforms/linux/amd64/kubectl ${MOUNT}/usr/bin/kubectl
tar xzvf kubernetes/server/kubernetes-server-linux-amd64.tar.gz
cp ./kubernetes/server/bin/hyperkube ${MOUNT}/usr/bin/hyperkube















































cat > ${MOUNT}/usr/lib/systemd/system/kube-apiserver.service << EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/apiserver
#User=kube
ExecStart=/usr/bin/hyperkube apiserver \
	    \$KUBE_LOGTOSTDERR \
	    \$KUBE_LOG_LEVEL \
	    \$KUBE_ETCD_SERVERS \
	    \$KUBE_API_ADDRESS \
	    \$KUBE_API_PORT \
	    \$KUBELET_PORT \
	    \$KUBE_ALLOW_PRIV \
	    \$KUBE_SERVICE_ADDRESSES \
	    \$KUBE_ADMISSION_CONTROL \
	    \$KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF








cat > ${MOUNT}/usr/lib/systemd/system/kube-controller-manager.service << EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/controller-manager
#User=kube
ExecStart=/usr/bin/hyperkube controller-manager \
	    \$KUBE_LOGTOSTDERR \
	    \$KUBE_LOG_LEVEL \
	    \$KUBE_MASTER \
	    \$KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF







cat > ${MOUNT}/usr/lib/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/proxy
ExecStart=/usr/bin/hyperkube proxy \
	    \$KUBE_LOGTOSTDERR \
	    \$KUBE_LOG_LEVEL \
	    \$KUBE_MASTER \
	    \$KUBE_PROXY_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF





cat > ${MOUNT}/usr/lib/systemd/system/kubelet-prep.service << EOF
[Unit]
Description=Kubernetes Kubelet Prep Service
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/mkdir -p /var/lib/kubelet
RemainAfterExit=true
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF



cat > ${MOUNT}/usr/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=kubelet-prep.service
Requires=kubelet-prep.service
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStartPre=/usr/bin/mkdir -p /var/lib/kubelet
ExecStart=/usr/bin/kubelet \
	    \$KUBE_LOGTOSTDERR \
	    \$KUBE_LOG_LEVEL \
	    \$KUBELET_API_SERVER \
	    \$KUBELET_ADDRESS \
	    \$KUBELET_PORT \
	    \$KUBELET_HOSTNAME \
	    \$KUBE_ALLOW_PRIV \
	    \$KUBELET_ARGS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

































umount ${MOUNT}
#losetup -d /dev/loop0
