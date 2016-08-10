#!/bin/bash

#systemctl stop etcd flannel docker sshd

/usr/bin/ip link set dev eth0 mtu 1450

ip link set dev eth0 down && ip link set dev eth0 up

cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF



growpart --update on /dev/vda 2
resize2fs /dev/vda2


































ETH0_IP=$(ip addr ls eth0 | awk '/inet / {split($2, ary, /\//); print ary[1]}')




cat > ${MOUNT}/usr/lib/systemd/system/etcd.service << EOF
[Unit]
Description=etcd
Requires=network.target
After=network.target
[Service]
ExecStartPre=/usr/bin/mkdir -p /var/lib/etcd
ExecStartPre=/usr/bin/ip link set dev eth0 mtu 1450
ExecStart=/bin/etcd \
        --name master \
        --data-dir /var/lib/etcd \
        --listen-peer-urls "http://127.0.0.1:2380,http://0.0.0.0:7001" \
        --listen-client-urls "http://127.0.0.1:2379,http://0.0.0.0:4001" \
        --advertise-client-urls "http://${ETH0_IP}:4001" \
        --initial-cluster "master=http://${ETH0_IP}:7001" \
        --initial-advertise-peer-urls "http://${ETH0_IP}:7001"
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

cat > ${MOUNT}/usr/lib/systemd/system/etcd-waiter.service << EOF
[Unit]
Description=etcd waiter
Wants=network-online.target
After=network-online.target
Before=flannel.service
Before=setup-network-environment.service
[Service]
ExecStartPre=/usr/bin/chmod +x /usr/bin/etcd-waiter.sh
ExecStart=/usr/bin/bash /usr/bin/etcd-waiter.sh
RemainAfterExit=true
Type=oneshot
EOF

cat >${MOUNT}/bin/etcd-waiter.sh << EOF
#! /usr/bin/bash
until curl http://${ETH0_IP}:4001/v2/machines; do sleep 1; done
EOF

cat > ${MOUNT}/usr/lib/systemd/system/flannel.service << EOF
[Unit]
Description=Flanneld Network Agent
After=etcd-waiter.service
Requires=etcd-waiter.service
[Service]
ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{"Network":"10.100.0.0/16", "Backend": {"Type": "host-gw"}}'
ExecStartPre=-/usr/sbin/ip link del docker0
ExecStart=/usr/bin/flanneld -etcd-endpoints http://${ETH0_IP}:4001
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

cat > ${MOUNT}/usr/lib/systemd/system/flannel-waiter.service << EOF
[Unit]
Description=FlannelD waiter
After=etcd-waiter.service
Requires=etcd-waiter.service
Before=docker.service
Before=setup-network-environment.service
[Service]
ExecStartPre=/usr/bin/chmod +x /usr/bin/flannel-waiter.sh
ExecStart=/usr/bin/bash /usr/bin/flannel-waiter.sh
RemainAfterExit=true
Type=oneshot
EOF

cat >${MOUNT}/bin/flannel-waiter.sh << EOF
#! /usr/bin/bash
#!/bin/bash
echo "Start"
### waiting to be exist file
while [ ! -f "/run/flannel/subnet.env" ];
do
  sleep 1
done
echo "file already exists, continuing"
EOF

rm -rf ${MOUNT}/usr/lib/systemd/system/docker.socket

cat > ${MOUNT}/usr/lib/systemd/system/docker.service << EOF
[Unit]
After=flannel.service
Requires=flannel.service
After=flannel-waiter.service
Description=Docker Application Container Engine
Documentation=http://docs.docker.io
[Service]
EnvironmentFile=/run/flannel/subnet.env
ExecStart=/usr/bin/docker daemon --bip=\${FLANNEL_SUBNET} \
                                 --mtu=\${FLANNEL_MTU} \
                                 -s overlay \
                                 -H unix:///var/run/docker.sock \
                                 -H tcp://127.0.0.1:2375 \
                                 --registry-mirror=http://10.40.0.4:5000 \
                                 --exec-driver=native
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

















mkdir -p ${MOUNT}/etc/kubernetes

cat > ${MOUNT}/etc/kubernetes/config << EOF
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=0"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow_privileged=false"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=http://${ETH0_IP}:8080"
EOF


cat > ${MOUNT}/etc/kubernetes/apiserver << EOF
###
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#

# The address on the local server to listen to.
KUBE_API_ADDRESS="--address=0.0.0.0"

# The port on the local server to listen on.
# KUBE_API_PORT="--port=8080"

# Port minions listen on
# KUBELET_PORT="--kubelet_port=10250"

# Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd_servers=http://${ETH0_IP}:4001"

# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

# default admission control policies
KUBE_ADMISSION_CONTROL="--admission_control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"

# Add your own!
KUBE_API_ARGS=""
EOF


cat > ${MOUNT}/etc/kubernetes/controller-manager << EOF
###
# The following values are used to configure the kubernetes controller-manager

# defaults from config and apiserver should be adequate

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS=""
EOF



cat > ${MOUNT}/etc/kubernetes/proxy << EOF
###
# kubernetes proxy config

# default config should be adequate

# Add your own!
KUBE_PROXY_ARGS=""
EOF


cat > ${MOUNT}/etc/kubernetes/scheduler << EOF
###
# kubernetes scheduler config

# default config should be adequate

# Add your own!
KUBE_SCHEDULER_ARGS=""
EOF







cat > ${MOUNT}/etc/kubernetes/kubelet << EOF
###
# kubernetes kubelet (minion) config

# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=${ETH0_IP}"

# The port for the info server to serve on
KUBELET_PORT="--port=10250"

# You may leave this blank to use the actual hostname
KUBELET_HOSTNAME="--hostname_override=master"

# location of the api-server
KUBELET_API_SERVER="--api_servers=http://${ETH0_IP}:8080"

# Add your own!
KUBELET_ARGS="--container_runtime=docker"
EOF































































systemctl stop docker
systemctl daemon-reload
systemctl restart etcd

ssh-keygen -A
systemctl start sshd
systemctl enable sshd


cp /usr/lib/docker/clear-2900-containers.img.xz /var/lib/docker/clear-2900-containers.img.xz || echo "could not copy base image"



curl -L https://storage.googleapis.com/kubernetes-release/release/v1.0.5/bin/linux/amd64/kubelet > /usr/bin/kubelet
chmod +x /usr/bin/kubelet



systemctl enable etcd flannel docker sshd

systemctl start docker



systemctl restart kube-apiserver.service
systemctl restart kube-controller-manager.service
systemctl restart kube-proxy.service
systemctl restart kube-scheduler.service
systemctl restart kubelet.service


curl -L https://storage.googleapis.com/kubernetes-release/release/v1.0.5/bin/linux/amd64/kubectl > /usr/bin/kubectl
chmod +x /usr/bin/kubectl

#mkdir -p /etc/kubernetes/addons
#curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/saltbase/salt/kube-addons/namespace.yaml > /etc/kubernetes/addons/namespace.yaml

#curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/kube-ui/kube-ui-rc.yaml > /etc/kubernetes/addons/kube-ui-rc.yaml
#curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/kube-ui/kube-ui-svc.yaml > /etc/kubernetes/addons/kube-ui-svc.yaml

#kubectl create -f /etc/kubernetes/addons/namespace.yaml
#kubectl create -f /etc/kubernetes/addons/kube-ui-rc.yaml --namespace=kube-system
#kubectl create -f /etc/kubernetes/addons/kube-ui-svc.yaml --namespace=kube-system


systemctl status kube-apiserver.service
systemctl status kube-controller-manager.service
systemctl status kube-proxy.service
systemctl status kube-scheduler.service
systemctl status kubelet.service


mkdir -p /etc/kubernetes/addons
curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/saltbase/salt/kube-addons/namespace.yaml > /etc/kubernetes/addons/namespace.yaml
curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/kube-ui/kube-ui-rc.yaml > /etc/kubernetes/addons/kube-ui-rc.yaml
curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/kube-ui/kube-ui-svc.yaml > /etc/kubernetes/addons/kube-ui-svc.yaml

kubectl create -f /etc/kubernetes/addons/namespace.yaml
kubectl create -f /etc/kubernetes/addons/kube-ui-rc.yaml --namespace=kube-system
kubectl create -f /etc/kubernetes/addons/kube-ui-svc.yaml --namespace=kube-system








# RKT
/usr/bin/groupadd docker
/usr/bin/gpasswd -a cloud docker


# RKT
/usr/bin/groupadd rkt
/usr/bin/rkt install
/usr/bin/gpasswd -a cloud rkt

