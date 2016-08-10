mkdir -p /etc/harbor
cat > /etc/harbor/network.env <<EOF
EXTERNAL_DNS=8.8.8.8
OS_DOMAIN=harboros.net
DOCKER_BOOTSTRAP_NETWORK=172.17.42.1/16
FLANNEL_CORE_NETWORK=10.96.0.0/15
FLANNEL_WAN_NETWORK=10.98.0.0/16
EOF

cat > /usr/local/bin/docker-bootstrap-daemon <<EOF
#!/bin/bash
set -e
source /etc/harbor/network.env
ip link set dev docker down || true
brctl delbr docker || true
brctl addbr docker || true
ip addr add \${DOCKER_BOOTSTRAP_NETWORK} dev docker || true
ip link set dev docker mtu 1500 || true
ip link set dev docker up || true

DOCKER_BOOTSTRAP_IP=\$(echo \${DOCKER_BOOTSTRAP_NETWORK} | awk -F '/' '{print \$1}')
exec /usr/bin/docker-current daemon \\
        --exec-opt native.cgroupdriver=systemd \\
        -H unix:///var/run/docker-bootstrap.sock \\
        -p /var/run/docker-bootstrap.pid \\
        --graph=/var/lib/docker-bootstrap \\
        --bridge=docker \\
        --dns="\${EXTERNAL_DNS}" \\
        --mtu=1500 \\
        --fixed-cidr=\${DOCKER_BOOTSTRAP_NETWORK} \\
        --ip=\${DOCKER_BOOTSTRAP_IP} \\
        --userland-proxy=false \\
        --storage-driver overlay
EOF
chmod +x /usr/local/bin/docker-bootstrap-daemon

cat > /etc/systemd/system/docker-bootstrap.service <<EOF
[Unit]
Description=Docker Bootstrap Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target cloud-init.service chronyd.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/docker-bootstrap-daemon
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


cat > /usr/bin/docker-bootstrap <<EOF
#!/bin/bash
docker -H unix:///var/run/docker-bootstrap.sock "\$@"
EOF
chmod +x /usr/bin/docker-bootstrap



systemctl daemon-reload
systemctl restart docker-bootstrap
systemctl enable docker-bootstrap

docker-bootstrap info


cat > /usr/local/bin/etcdctl-network <<EOF
#!/bin/bash
set -e
source /etc/harbor/network.env
exec etcdctl \\
--ca-file /etc/harbor/auth/host/ca.crt \\
--cert-file /etc/harbor/auth/host/host.crt \\
--key-file /etc/harbor/auth/host/host.key \\
--endpoint https://etcd-network.harboros.net:4001 "\$@"
EOF
chmod +x /usr/local/bin/etcdctl-network


cat > /usr/local/bin/etcdctl-kube <<EOF
#!/bin/bash
set -e
source /etc/harbor/network.env
exec etcdctl \\
--ca-file /etc/harbor/auth/host/ca.crt \\
--cert-file /etc/harbor/auth/host/host.crt \\
--key-file /etc/harbor/auth/host/host.key \\
--endpoint https://etcd-kube.harboros.net:4002 "\$@"
EOF
chmod +x /usr/local/bin/etcdctl-kube


cat > /usr/local/bin/etcdctl-docker <<EOF
#!/bin/bash
set -e
source /etc/harbor/network.env
exec etcdctl \\
--ca-file /etc/harbor/auth/host/ca.crt \\
--cert-file /etc/harbor/auth/host/host.crt \\
--key-file /etc/harbor/auth/host/host.key \\
--endpoint https://etcd-docker.harboros.net:4003 "\$@"
EOF
chmod +x /usr/local/bin/etcdctl-docker


touch /etc/master-node

cat > /usr/local/bin/skydns-daemon <<EOF
#!/bin/bash
set -e
source /etc/harbor/network.env

if [ -f /etc/master-node ]
  then
    if etcdctl-network ls ; then
        echo "Command succeeded"
    else
        echo "Command failed"
        docker-bootstrap stop bootstrap-etcd-network || true
        docker-bootstrap rm bootstrap-etcd-network || true
        docker-bootstrap run -d \\
        --name bootstrap-etcd-network \\
        -p 127.0.0.1:4001:4001 \\
        -p 127.0.0.1:7001:7001 \\
        -v /var/lib/harbor/etcd/network:/var/etcd:rw \\
        -v /etc/harbor/auth/etcd-network/ca.crt:/etc/os-ssl/ca:ro \\
        -v /etc/harbor/auth/etcd-network/etcd-network.crt:/etc/os-ssl/cirt:ro \\
        -v /etc/harbor/auth/etcd-network/etcd-network.key:/etc/os-ssl/key:ro \\
        docker.io/port/system-etcd:latest \\
        etcd \\
        --name=master \\
        --data-dir=/var/etcd \\
        --listen-client-urls=https://0.0.0.0:4001 \\
        --listen-peer-urls=https://0.0.0.0:7001 \\
        --advertise-client-urls=https://etcd-network.\${OS_DOMAIN}:4001 \\
        --initial-advertise-peer-urls="https://\$(hostname -s).\${OS_DOMAIN}:7001" \\
        --initial-cluster="master=https://\$(hostname -s).\${OS_DOMAIN}:7001" \\
        --initial-cluster-token='etcd-cluster' \\
        --ca-file=/etc/os-ssl/ca \\
        --cert-file=/etc/os-ssl/cirt \\
        --key-file=/etc/os-ssl/key \\
        --peer-ca-file=/etc/os-ssl/ca \\
        --peer-cert-file=/etc/os-ssl/cirt \\
        --peer-key-file=/etc/os-ssl/key
    fi
fi

docker-bootstrap stop skydns || true
docker-bootstrap kill skydns || true
docker-bootstrap rm -v skydns || true
docker-bootstrap run \\
    --name skydns \\
    -d \\
    --net=host \\
    -p 172.17.42.1:53:53 \\
    -v /etc/harbor/auth/host/ca.crt:/etc/os-ssl/ca:ro \\
    -v /etc/harbor/auth/host/host.crt:/etc/os-ssl/cirt:ro \\
    -v /etc/harbor/auth/host/host.key:/etc/os-ssl/key:ro \\
    docker.io/port/system-skydns:latest \\
        -addr="172.17.42.1:53" \\
        -nameservers="\${EXTERNAL_DNS}:53" \\
        -machines="https://etcd-network.\${OS_DOMAIN}:4001" \\
        -ca-cert="/etc/os-ssl/ca" \\
        -tls-pem="/etc/os-ssl/cirt" \\
        -tls-key="/etc/os-ssl/key"

until dig skydns.local @172.17.42.1
do
  echo "Waiting for SKYDNS to respond"
  sleep 2
done
echo "nameserver 172.17.42.1" > /etc/resolv.conf
echo "# Generated by HarborOS" >> /etc/resolv.conf



EOF
chmod +x /usr/local/bin/skydns-daemon






cat > /etc/systemd/system/skydns.service <<EOF
[Unit]
Description=Skydns per-node agent
Requires=docker-bootstrap.service
After=docker-bootstrap.service
Before=docker.service flannel.service

[Service]
User=root
ExecStartPre=/usr/local/bin/skydns-daemon
ExecStart=/usr/local/bin/etcdctl-network watch /skydns/config
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF



systemctl daemon-reload
systemctl restart skydns
systemctl enable skydns



cat > /etc/systemd/system/openvswitch.service <<EOF
[Unit]
Description=OpenvSwitch
After=network.target docker-bootstrap.service
Requires=network.target docker-bootstrap.service

[Service]
StandardOutput=null
TimeoutStartSec=0
Type=simple
ExecStartPre=/usr/sbin/modprobe openvswitch
ExecStartPre=-/usr/bin/docker-bootstrap pull docker.io/port/system-ovs:latest

ExecStartPre=-/usr/bin/docker-bootstrap stop ovs-install
ExecStartPre=-/usr/bin/docker-bootstrap kill ovs-install
ExecStartPre=-/usr/bin/docker-bootstrap rm ovs-install
ExecStartPre=/usr/bin/docker-bootstrap run \
              --name ovs-install \
              --net=host \
              -v /:/host \
               docker.io/port/system-ovs:latest harbor-install
ExecStartPre=-/usr/bin/docker-bootstrap stop ovs-install
ExecStartPre=-/usr/bin/docker-bootstrap kill ovs-install
ExecStartPre=-/usr/bin/docker-bootstrap rm ovs-install

ExecStartPre=-/usr/bin/docker-bootstrap stop ovs
ExecStartPre=-/usr/bin/docker-bootstrap kill ovs
ExecStartPre=-/usr/bin/docker-bootstrap rm ovs
ExecStartPre=/usr/bin/docker-bootstrap run \
              --name ovs \
              --restart=always \
              -d \
              --net=host \
              --privileged \
              --cap-add NET_ADMIN \
              -v /dev/net:/dev/net \
              -v /var/run/openvswitch:/var/run/openvswitch \
              -v /var/lib/openvswitch:/var/lib/openvswitch \
               docker.io/port/system-ovs:latest
ExecStart=/usr/bin/docker-bootstrap wait ovs

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart openvswitch
systemctl enable openvswitch
ovs-vsctl show











cat > /usr/local/bin/flannel-daemon <<EOF
#!/bin/bash
source /etc/harbor/network.env

HOST_FLANNEL_PUBLIC_DEV=eth0

if [ -f /etc/master-node ]
  then
    if etcdctl-network ls ; then
        echo "Command succeeded"
    else
        echo "Command failed"
        docker-bootstrap stop bootstrap-etcd-network || true
        docker-bootstrap rm bootstrap-etcd-network || true
        docker-bootstrap run -d \\
        --name bootstrap-etcd-network \\
        -p 127.0.0.1:4001:4001 \\
        -p 127.0.0.1:7001:7001 \\
        -v /var/lib/harbor/etcd/network:/var/etcd:rw \\
        -v /etc/harbor/auth/etcd-network/ca.crt:/etc/os-ssl/ca:ro \\
        -v /etc/harbor/auth/etcd-network/etcd-network.crt:/etc/os-ssl/cirt:ro \\
        -v /etc/harbor/auth/etcd-network/etcd-network.key:/etc/os-ssl/key:ro \\
        docker.io/port/system-etcd:latest \\
        etcd \\
        --name=master \\
        --data-dir=/var/etcd \\
        --listen-client-urls=https://0.0.0.0:4001 \\
        --listen-peer-urls=https://0.0.0.0:7001 \\
        --advertise-client-urls=https://etcd-network.\${OS_DOMAIN}:4001 \\
        --initial-advertise-peer-urls="https://\$(hostname -s).\${OS_DOMAIN}:7001" \\
        --initial-cluster="master=https://\$(hostname -s).\${OS_DOMAIN}:7001" \\
        --initial-cluster-token='etcd-cluster' \\
        --ca-file=/etc/os-ssl/ca \\
        --cert-file=/etc/os-ssl/cirt \\
        --key-file=/etc/os-ssl/key \\
        --peer-ca-file=/etc/os-ssl/ca \\
        --peer-cert-file=/etc/os-ssl/cirt \\
        --peer-key-file=/etc/os-ssl/key
    fi
fi



HOST_FLANNEL_PUBLIC_IP=\$(ip -f inet -o addr show \$HOST_FLANNEL_PUBLIC_DEV|cut -d\  -f 7 | cut -d/ -f 1)
docker-bootstrap stop flannel || true
docker-bootstrap kill flannel || true
docker-bootstrap rm -v flannel || true
docker-bootstrap run \\
    --name flannel \\
    --net=host \\
    --privileged \\
    --restart=always \\
    -d \\
    -v /dev/net:/dev/net:rw \\
    -v /run/flannel:/run/flannel:rw \\
    -v /etc/harbor/auth/host/ca.crt:/etc/os-ssl/ca:ro \\
    -v /etc/harbor/auth/host/host.crt:/etc/os-ssl/cirt:ro \\
    -v /etc/harbor/auth/host/host.key:/etc/os-ssl/key:ro \\
    docker.io/port/system-flannel:latest \\
      /opt/bin/flanneld \\
      --ip-masq=true \\
      --alsologtostderr=true \\
      --iface=eth0 \\
      --etcd-prefix="/flannel/network" \\
      --public-ip="\${HOST_FLANNEL_PUBLIC_IP}" \\
      -networks="core,wan" \\
      -etcd-cafile="/etc/os-ssl/ca" \\
      -etcd-certfile="/etc/os-ssl/cirt" \\
      -etcd-keyfile="/etc/os-ssl/key" \\
      -etcd-endpoints="https://etcd-network.harboros.net:4001"

if [ -f /etc/master-node ]
  then
    until etcdctl-network set /flannel/network/core/config "{ \"Network\": \"\${FLANNEL_CORE_NETWORK}\", \"Backend\": { \"Type\": \"host-gw\" } }"
    do
         echo "Waiting for ETCD"
         sleep 5
    done
    until etcdctl-network set /flannel/network/wan/config "{ \"Network\": \"\${FLANNEL_WAN_NETWORK}\", \"Backend\": { \"Type\": \"vxlan\", \"VNI\": 1 } }"
    do
         echo "Waiting for ETCD"
         sleep 5
    done
    until [ -f /var/run/flannel/networks/core.env ]
    do
         echo "Waiting for Flannel subnet"
         sleep 5
    done
fi


EOF
chmod +x /usr/local/bin/flannel-daemon





cat > /etc/systemd/system/flannel.service <<EOF
[Unit]
Description=Flannel per-node agent
Requires=docker-bootstrap.service
After=docker-bootstrap.service
Before=docker.service

[Service]
User=root
ExecStartPre=/usr/local/bin/flannel-daemon
ExecStart=/usr/bin/docker-bootstrap wait flannel
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF



systemctl daemon-reload
systemctl restart flannel
systemctl enable flannel



















cat > /usr/local/bin/docker-wan-daemon << EOF
#!/bin/bash
set -e
PATH=\${PATH}:/usr/local/bin
source /var/run/flannel/networks/wan.env
source /etc/harbor/network.env

HOST_SKYDNS_IP=\$(echo \${DOCKER_BOOTSTRAP_NETWORK} | awk -F '/' '{ print \$1 }')
HOST_DOCKER_ADMIN_IP=\$(echo \${FLANNEL_SUBNET} | awk -F '/' '{print \$1}')

ip link set dev docker1 down || true
brctl delbr docker1 || true
brctl addbr docker1 || true
ip addr add \${FLANNEL_SUBNET} dev docker1 || true
ip link set dev docker1 mtu ${FLANNEL_MTU} || true
ip link set dev docker1 up || true

exec /usr/bin/docker-current daemon \\
        --exec-opt native.cgroupdriver=systemd \\
        -H unix:///var/run/docker-wan.sock \\
        -H tcp://\${HOST_DOCKER_ADMIN_IP}:2375 \\
        -p /var/run/docker-wan.pid \\
        --graph=/var/lib/docker-wan \\
        --bridge=docker1 \\
        --dns=\${HOST_SKYDNS_IP} \\
        --mtu=\${FLANNEL_MTU} \\
        --fixed-cidr=\${FLANNEL_SUBNET} \\
        --userland-proxy=false \\
        --storage-driver=overlay \\
        --cluster-advertise="docker1:2375" \\
        --cluster-store="etcd://etcd-docker.\${OS_DOMAIN}:4003" \\
        --cluster-store-opt="kv.cacertfile=/etc/harbor/auth/host/ca.crt" \\
        --cluster-store-opt="kv.certfile=/etc/harbor/auth/host/host.crt" \\
        --cluster-store-opt="kv.keyfile=/etc/harbor/auth/host/host.key" \\
        --tls \\
        --tlsverify \\
        --tlscacert="/etc/harbor/auth/host/ca.crt" \\
        --tlscert="/etc/harbor/auth/host/host.crt" \\
        --tlskey="/etc/harbor/auth/host/host.key"
EOF
chmod +x /usr/local/bin/docker-wan-daemon



cat > /etc/systemd/system/docker-wan.service <<EOF
[Unit]
Description=Docker Wan Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target cloud-init.service chronyd.service flannel.service
Requires=flannel.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/docker-wan-daemon
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


cat > /usr/bin/docker-wan <<EOF
#!/bin/bash
docker -H unix:///var/run/docker-wan.sock "\$@"
EOF
chmod +x /usr/bin/docker-wan


systemctl daemon-reload
systemctl restart docker-wan
systemctl enable docker-wan












cat > /usr/local/bin/docker-daemon <<EOF
#!/bin/bash
set -e
PATH=/usr/local/bin:${PATH}
source /var/run/flannel/networks/core.env
source /etc/harbor/network.env

HOST_SKYDNS_IP=\$(echo \${DOCKER_BOOTSTRAP_NETWORK} | awk -F '/' '{ print \$1 }')

ip link set docker0 down || true
brctl delbr docker0 || true

docker-bootstrap stop bootstrap-etcd-network || true
docker-bootstrap kill bootstrap-etcd-network || true
docker-bootstrap rm bootstrap-etcd-network || true

exec /usr/bin/docker-current daemon \\
        --exec-opt native.cgroupdriver=systemd \\
        -H unix:///var/run/docker.sock \\
        -p /var/run/docker.pid \\
        --graph=/var/lib/docker \\
        --dns=\${HOST_SKYDNS_IP} \\
        --bip=\${FLANNEL_SUBNET} \\
        --mtu=\${FLANNEL_MTU} \\
        --userland-proxy=false \\
        --storage-driver overlay
EOF
chmod +x /usr/local/bin/docker-daemon



cat > /etc/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target cloud-init.service chronyd.service flannel.service docker-wan.service
Requires=flannel.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/docker-daemon
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker





mkdir -p /etc/cni/net.d
cat > /etc/cni/net.d/10-calico.conf <<EOF
{
    "name": "calico-k8s-network",
    "type": "calico",
    "etcd_authority": "etcd-network.$(hostname -d):4001",
    "log_level": "info",
    "ipam": {
        "type": "calico-ipam"
    }
}
EOF



mkdir -p /etc/kubernetes
cat > /etc/kubernetes/docker-compose.yml <<EOF
version: "2"
services:
  kubelet:
    container_name: "kubelet"
    image: "docker.io/port/system-kube:latest"
    restart: "always"
    privileged: true
    network_mode: "host"
    pid: "host"
    environment:
      - ETCD_AUTHORITY=etcd-network.$(hostname -d):4001
      - ETCD_SCHEME=https
      - ETCD_CA_CERT_FILE=/etc/harbor/auth/host/ca.crt
      - ETCD_CERT_FILE=/etc/harbor/auth/host/host.crt
      - ETCD_KEY_FILE=/etc/harbor/auth/host/host.key
    volumes:
      - "/sys:/sys:ro"
      - "/var/run:/var/run:rw"
      - "/:/rootfs:ro"
      - "/dev:/dev:rw"
      - "/etc/cni/net.d:/etc/cni/net.d:rw"
      - "/var/lib/docker:/var/lib/docker:rw"
      - "/var/lib/kubelet:/var/lib/kubelet:rw"
      - "/etc/os-release:/etc/os-release:ro"
      - "/etc/kubernetes/manifests:/etc/kubernetes/manifests:ro"
      - "/etc/harbor/auth/host/ca.crt:/etc/harbor/auth/host/ca.crt:ro"
      - "/etc/harbor/auth/host/host.crt:/etc/harbor/auth/host/host.crt:ro"
      - "/etc/harbor/auth/host/host.key:/etc/harbor/auth/host/host.key:ro"
      - "/etc/harbor/auth/kubelet/kubeconfig.yaml:/etc/harbor/auth/kubelet/kubeconfig.yaml:ro"
    command:
      - "/hyperkube"
      - "kubelet"
      - "--v=3"
      - "--port=10250"
      - "--read-only-port=0"
      - "--address=0.0.0.0"
      - "--allow-privileged=true"
      - "--cluster-dns=172.17.42.1"
      - "--cluster-domain=$(hostname -d)"
      - "--config=/etc/kubernetes/manifests"
      - "--hostname-override=$(hostname -s).$(hostname -d)"
      - "--api-servers=https://kubernetes.$(hostname -d):6443"
      - "--logtostderr=true"
      - "--docker=unix:///var/run/docker.sock"
      - "--network-plugin-dir=/etc/cni/net.d"
      - "--network-plugin=cni"
      - "--pod-infra-container-image=docker.io/port/pause:latest"
      - "--kubeconfig=/etc/harbor/auth/kubelet/kubeconfig.yaml"
      - "--tls-cert-file=/etc/harbor/auth/host/host.crt"
      - "--tls-private-key-file=/etc/harbor/auth/host/host.key"
EOF


cat > /usr/bin/kubectl <<EOF
#!/bin/bash
set -e
PATH=/usr/local/bin:${PATH}
exec docker exec -it kubelet \
    /opt/harbor/assets/host/bin/kubectl \
    --kubeconfig=/etc/harbor/auth/kubelet/kubeconfig.yaml \
    --server=https://kubernetes.harboros.net:6443 "\$@"
EOF
chmod +x /usr/bin/kubectl



cat > /usr/local/bin/kubelet-daemon-start <<EOF
#!/bin/bash
set -e
PATH=/usr/local/bin:${PATH}
cd /etc/kubernetes
/usr/bin/docker-compose --project-name kubernetes pull
/usr/bin/docker-compose --project-name kubernetes down || true
/usr/bin/docker-compose --project-name kubernetes up -d
EOF
chmod +x /usr/local/bin/kubelet-daemon-start

cat > /usr/local/bin/kubelet-daemon-monitor <<EOF
#!/bin/bash
set -e
PATH=/usr/local/bin:${PATH}
cd /etc/kubernetes
/usr/bin/docker wait \$(/usr/bin/docker-compose --project-name kubernetes ps -q | head -n 1)
EOF
chmod +x /usr/local/bin/kubelet-daemon-monitor

cat > /usr/local/bin/kubelet-daemon-stop <<EOF
#!/bin/bash
set -e
PATH=/usr/local/bin:${PATH}
cd /etc/kubernetes
/usr/bin/docker-compose --project-name kubernetes down

EOF
chmod +x /usr/local/bin/kubelet-daemon-stop

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

curl -L https://github.com/docker/compose/releases/download/1.6.2/run.sh > /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose





systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet



mkdir -p /etc/kubernetes/manifests



cat > /etc/kubernetes/manifests/etcd-network.manifest <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: etcd-network
spec:
  hostNetwork: true
  containers:
  - name: etcd-network
    image: docker.io/port/system-etcd:latest
    ports:
    - containerPort: 4001
      hostPort: 4001
      name: etcd
    - containerPort: 7001
      hostPort: 7001
      name: peers
    command:
    - etcd
    - --name=master
    - --data-dir=/var/etcd
    - --listen-client-urls=https://0.0.0.0:4001
    - --listen-peer-urls=https://0.0.0.0:7001
    - --advertise-client-urls=https://etcd-network.$(hostname -d):4001
    - --ca-file=/etc/os-ssl/ca.crt
    - --cert-file=/etc/os-ssl/etcd-network.crt
    - --key-file=/etc/os-ssl/etcd-network.key
    - --peer-ca-file=/etc/os-ssl/ca.crt
    - --peer-cert-file=/etc/os-ssl/etcd-network.crt
    - --peer-key-file=/etc/os-ssl/etcd-network.key
    volumeMounts:
      - mountPath: /etc/os-ssl
        name: os-ssl
      - mountPath: /var/etcd
        name: var-etcd
  volumes:
    - name: "os-ssl"
      hostPath:
        path: "/etc/harbor/auth/etcd-network"
    - name: "var-etcd"
      hostPath:
        path: "/var/lib/harbor/etcd/network"
EOF





cat > /usr/local/bin/calico-daemon <<EOF
#!/bin/bash
set -e
PATH=/usr/local/bin:\${PATH}
source /etc/harbor/network.env
export ETCD_AUTHORITY=etcd-network.harboros.net:4001
export ETCD_SCHEME=https
export ETCD_CA_CERT_FILE=/etc/harbor/auth/host/ca.crt
export ETCD_CERT_FILE=/etc/harbor/auth/host/host.crt
export ETCD_KEY_FILE=/etc/harbor/auth/host/host.key

HOST_EXTERNAL_DEV=\$(ip route get "\${EXTERNAL_DNS}" | grep -Po '(?<=(dev )).*(?= src)')
HOST_CALICO_IP=\$(ip -f inet -o addr show \$HOST_EXTERNAL_DEV|cut -d\  -f 7 | cut -d/ -f 1)
export DEFAULT_IPV4=\${HOST_CALICO_IP}
exec calicoctl node \\
    --ip=\${HOST_CALICO_IP} \\
    --detach=false \\
    --node-image=docker.io/port/system-calico:latest
EOF
chmod +x /usr/local/bin/calico-daemon

cat > /etc/systemd/system/calico.service <<EOF
[Unit]
Description=Calico per-node agent
Documentation=https://github.com/projectcalico/calico-docker
Requires=docker.service
After=docker.service

[Service]
ExecStart=/usr/local/bin/calico-daemon
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


curl -L http://www.projectcalico.org/builds/calicoctl > /usr/bin/calicoctl
chmod +x /usr/bin/calicoctl


systemctl daemon-reload
systemctl restart calico
systemctl enable calico



cat > /etc/kubernetes/manifests/etcd-kube.manifest <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: etcd-kube
spec:
  hostNetwork: true
  containers:
  - name: etcd-kube
    image: docker.io/port/system-etcd:latest
    ports:
    - containerPort: 4002
      hostPort: 4002
      name: etcd
    - containerPort: 7002
      hostPort: 7002
      name: peers
    command:
    - etcd
    - --name=master
    - --data-dir=/var/etcd
    - --listen-client-urls=https://0.0.0.0:4002
    - --listen-peer-urls=https://0.0.0.0:7002
    - --advertise-client-urls=https://etcd-kube.$(hostname -d):4002
    - --initial-cluster-token='etcd-cluster'
    - --ca-file=/etc/os-ssl/ca.crt
    - --cert-file=/etc/os-ssl/etcd-kube.crt
    - --key-file=/etc/os-ssl/etcd-kube.key
    - --peer-ca-file=/etc/os-ssl/ca.crt
    - --peer-cert-file=/etc/os-ssl/etcd-kube.crt
    - --peer-key-file=/etc/os-ssl/etcd-kube.key
    volumeMounts:
      - mountPath: /etc/os-ssl
        name: os-ssl
      - mountPath: /var/etcd
        name: etcd-kube
  volumes:
    - name: "os-ssl"
      hostPath:
        path: "/etc/harbor/auth/etcd-kube"
    - name: "etcd-kube"
      hostPath:
        path: "/var/lib/harbor/etcd/kube"
EOF



cat > /etc/kubernetes/manifests/etcd-docker.manifest <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: etcd-docker
spec:
  hostNetwork: true
  containers:
  - name: etcd-docker
    image: docker.io/port/system-etcd:latest
    ports:
    - containerPort: 4003
      hostPort: 4003
      name: etcd
    - containerPort: 7003
      hostPort: 7003
      name: peers
    command:
    - etcd
    - --name=master
    - --data-dir=/var/etcd
    - --listen-client-urls=https://0.0.0.0:4003
    - --listen-peer-urls=https://0.0.0.0:7003
    - --advertise-client-urls=https://etcd-docker.$(hostname -d):4003
    - --initial-cluster-token='etcd-cluster'
    - --ca-file=/etc/os-ssl/ca.crt
    - --cert-file=/etc/os-ssl/etcd-docker.crt
    - --key-file=/etc/os-ssl/etcd-docker.key
    - --peer-ca-file=/etc/os-ssl/ca.crt
    - --peer-cert-file=/etc/os-ssl/etcd-docker.crt
    - --peer-key-file=/etc/os-ssl/etcd-docker.key
    volumeMounts:
      - mountPath: /etc/os-ssl
        name: os-ssl
      - mountPath: /var/etcd
        name: etcd-swarm
  volumes:
    - name: "os-ssl"
      hostPath:
        path: "/etc/harbor/auth/etcd-docker"
    - name: "etcd-swarm"
      hostPath:
        path: "/var/lib/harbor/etcd/docker"
EOF

calicoctl pool add 192.168.0.0/16 --nat-outgoing --ipip












cat > /usr/local/bin/docker-swarm-daemon << EOF
#!/bin/bash
set -e
PATH=/usr/local/bin:\${PATH}
source /etc/harbor/network.env

docker stop swarm-node || true
docker kill swarm-node || true
docker rm -v swarm-node || true

exec docker run \\
      -d \\
      --restart=always \\
      --name swarm-node \\
      --net=host \\
      -v /etc/harbor/auth/host/ca.crt:/etc/harbor/auth/host/ca.crt:ro \\
      -v /etc/harbor/auth/host/host.crt:/etc/harbor/auth/host/host.crt:ro \\
      -v /etc/harbor/auth/host/host.key:/etc/harbor/auth/host/host.key:ro \\
      docker.io/port/system-swarm:latest \\
          join \\
          --advertise=\$(hostname -s).\${OS_DOMAIN}:2375 \\
          --discovery-opt "kv.cacertfile=/etc/harbor/auth/host/ca.crt" \\
          --discovery-opt "kv.certfile=/etc/harbor/auth/host/host.crt" \\
          --discovery-opt "kv.keyfile=/etc/harbor/auth/host/host.key" \\
          etcd://etcd-docker.\${OS_DOMAIN}:4003
EOF
chmod +x /usr/local/bin/docker-swarm-daemon


cat > /etc/systemd/system/docker-swarm.service <<EOF
[Unit]
Description=Docker Swarm Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target cloud-init.service chronyd.service docker-wan.service
Requires=docker-wan.service
Wants=network-online.target

[Service]
ExecStartPre=/usr/local/bin/docker-swarm-daemon
ExecStart=/usr/bin/docker wait swarm-node
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF




systemctl daemon-reload
systemctl restart docker-swarm
systemctl enable docker-swarm




cat > /usr/local/bin/docker-swarm-manager-daemon << EOF
#!/bin/bash
set -e
source /etc/harbor/network.env

docker stop swarm-manager || true
docker kill swarm-manager || true
docker rm -v swarm-manager || true
exec docker run -d \\
    --name swarm-manager \\
    --net=host \\
    -v /etc/harbor/auth/host/ca.crt:/etc/harbor/auth/host/ca.crt:ro \\
    -v /etc/harbor/auth/host/host.crt:/etc/harbor/auth/host/host.crt:ro \\
    -v /etc/harbor/auth/host/host.key:/etc/harbor/auth/host/host.key:ro \\
    -v /etc/harbor/auth/docker-swarm/ca.crt:/etc/harbor/auth/docker-swarm/ca.crt:ro \\
    -v /etc/harbor/auth/docker-swarm/docker-swarm.crt:/etc/harbor/auth/docker-swarm/docker-swarm.crt:ro \\
    -v /etc/harbor/auth/docker-swarm/docker-swarm.key:/etc/harbor/auth/docker-swarm/docker-swarm.key:ro \\
    docker.io/port/system-swarm:latest \\
        manage etcd://etcd-docker.\${OS_DOMAIN}:4003  \\
        --discovery-opt "kv.cacertfile=/etc/harbor/auth/host/ca.crt" \\
        --discovery-opt "kv.certfile=/etc/harbor/auth/host/host.crt" \\
        --discovery-opt "kv.keyfile=/etc/harbor/auth/host/host.key" \\
        --tlsverify \\
        --tlscacert=/etc/harbor/auth/docker-swarm/ca.crt \\
        --tlscert=/etc/harbor/auth/docker-swarm/docker-swarm.crt \\
        --tlskey=/etc/harbor/auth/docker-swarm/docker-swarm.key \\
        -H tcp://docker-swarm.\${OS_DOMAIN}:4000
EOF
chmod +x /usr/local/bin/docker-swarm-manager-daemon

cat > /etc/systemd/system/docker-swarm-manager.service <<EOF
[Unit]
Description=Docker Swarm Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target cloud-init.service chronyd.service docker-wan.service
Requires=docker-wan.service
Wants=network-online.target

[Service]
ExecStartPre=/usr/local/bin/docker-swarm-manager-daemon
ExecStart=/usr/bin/docker wait swarm-manager
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/bin/swarm <<EOF
#!/bin/bash
set -e
source /etc/harbor/network.env

exec docker \\
    -H="tcp://docker-swarm.\${OS_DOMAIN}:4000" \\
    --tls \\
    --tlscacert="/etc/harbor/auth/host/ca.crt" \\
    --tlscert="/etc/harbor/auth/host/host.crt" \\
    --tlskey="/etc/harbor/auth/host/host.key" \\
    --tlsverify \\
    "\$@"
EOF
chmod +x /usr/bin/swarm


systemctl daemon-reload
systemctl restart docker-swarm-manager
systemctl stop docker-swarm-manager
systemctl enable docker-swarm-manager



systemctl enable docker-bootstrap
systemctl enable skydns
systemctl enable openvswitch
systemctl enable flannel
systemctl enable docker-wan
systemctl enable docker
systemctl enable kubelet
systemctl enable calico
systemctl enable docker-swarm
systemctl enable docker-swarm-manager



systemctl restart docker-bootstrap
systemctl restart skydns
systemctl restart openvswitch
systemctl restart flannel
systemctl restart docker-wan
systemctl restart docker
systemctl restart calico
systemctl restart kubelet
systemctl restart docker-swarm
systemctl restart docker-swarm-manager
systemctl status docker-swarm
systemctl status docker-swarm-manager








cat > /etc/kubernetes/manifests/kube-apiserver.manifest <<EOF
apiVersion: v1
kind: Pod
metadata:
  namespace: kube-system
  name: kube-apiserver
spec:
  hostNetwork: true
  containers:
  - name: kube-apiserver
    image: docker.io/port/system-kube:latest
    ports:
    - containerPort: 6443
      hostPort: 6443
      name: kube
    command:
    - /hyperkube
    - apiserver
    - --alsologtostderr=true
    - --bind-address=0.0.0.0
    - --secure-port=6443
    - --v=2
    - --etcd_servers=https://etcd-kube.$(hostname -d):4002
    - --etcd-cafile=/etc/harbor/auth/host/ca.crt
    - --etcd-certfile=/etc/harbor/auth/host/host.crt
    - --etcd-keyfile=/etc/harbor/auth/host/host.key
    - --tls-cert-file=/etc/harbor/auth/kubernetes/kubernetes.crt
    - --tls-private-key-file=/etc/harbor/auth/kubernetes/kubernetes.key
    - --client-ca-file=/etc/harbor/auth/kubernetes/ca.crt
    - --kubelet-certificate-authority=/etc/harbor/auth/kubelet/ca.crt
    - --kubelet-client-certificate=/etc/harbor/auth/kubelet/kubelet.crt
    - --kubelet-client-key=/etc/harbor/auth/kubelet/kubelet.key
    - --insecure-bind-address=127.0.0.1
    - --insecure-port=8080
    - --allow_privileged=true
    - --service-cluster-ip-range=10.100.0.0/24
    - --service-node-port-range=22-30000
    - --runtime-config=extensions/v1beta1/daemonsets=true,extensions/v1beta1/jobs=true
    volumeMounts:
      - mountPath: /etc/harbor/auth/host
        name: os-ssl-host
      - mountPath: /etc/harbor/auth/kubernetes
        name: os-ssl-kubernetes
      - mountPath: /etc/harbor/auth/kubelet
        name: os-ssl-kubelet
  volumes:
  - name: os-ssl-host
    hostPath:
      path: "/etc/harbor/auth/host"
  - name: os-ssl-kubernetes
    hostPath:
      path: "/etc/harbor/auth/kubernetes"
  - name: os-ssl-kubelet
    hostPath:
      path: "/etc/harbor/auth/kubelet"
EOF




cat > /etc/kubernetes/manifests/kube-controller-manager.manifest <<EOF
apiVersion: v1
kind: Pod
metadata:
  namespace: kube-system
  name: kube-controller-manager
spec:
  hostNetwork: true
  containers:
  - name: kube-controller-manager
    image: docker.io/port/system-kube:latest
    command:
    - /hyperkube
    - controller-manager
    - --alsologtostderr=true
    - --master=https://kubernetes.$(hostname -d):6443
    - --kubeconfig=/etc/harbor/auth/kubelet/kubeconfig.yaml
    volumeMounts:
      - mountPath: /etc/ssl/certs/ca-certificates.crt
        name: os-ssl-kubelet-ca
      - mountPath: /etc/harbor/auth/kubelet/kubeconfig.yaml
        name: os-kubelet-config
  volumes:
  - name: os-ssl-kubelet-ca
    hostPath:
      path: "/etc/harbor/auth/kubelet/ca.crt"
  - name: os-kubelet-config
    hostPath:
      path: "/etc/harbor/auth/kubelet/kubeconfig.yaml"
EOF




cat > /etc/kubernetes/manifests/kube-scheduler.manifest <<EOF
apiVersion: v1
kind: Pod
metadata:
  namespace: kube-system
  name: kube-scheduler
spec:
  hostNetwork: true
  containers:
  - name: kube-scheduler
    image: docker.io/port/system-kube:latest
    command:
    - /hyperkube
    - scheduler
    - --alsologtostderr=true
    - --master=https://kubernetes.$(hostname -d):6443
    - --kubeconfig=/etc/harbor/auth/kubelet/kubeconfig.yaml
    volumeMounts:
      - mountPath: /etc/ssl/certs/ca-certificates.crt
        name: os-ssl-kubelet-ca
      - mountPath: /etc/harbor/auth/kubelet/kubeconfig.yaml
        name: os-kubelet-config
  volumes:
  - name: os-ssl-kubelet-ca
    hostPath:
      path: "/etc/harbor/auth/kubelet/ca.crt"
  - name: os-kubelet-config
    hostPath:
      path: "/etc/harbor/auth/kubelet/kubeconfig.yaml"
EOF

cat > /etc/kubernetes/manifests/kube-proxy.manifest <<EOF
apiVersion: v1
kind: Pod
metadata:
  namespace: kube-system
  name: kube-proxy
spec:
  hostNetwork: true
  containers:
  - name: kube-proxy
    image: docker.io/port/system-kube:latest
    command:
    - /hyperkube
    - proxy
    - --proxy-mode=iptables
    - --alsologtostderr=true
    - --bind-address=0.0.0.0
    - --master=https://kubernetes.$(hostname -d):6443
    - --kubeconfig=/etc/harbor/auth/kubelet/kubeconfig.yaml
    securityContext:
      privileged: true
    volumeMounts:
      - mountPath: /etc/ssl/certs/ca-certificates.crt
        name: os-ssl-kubelet-ca
      - mountPath: /etc/harbor/auth/kubelet/kubeconfig.yaml
        name: os-kubelet-config
  volumes:
  - name: os-ssl-kubelet-ca
    hostPath:
      path: "/etc/harbor/auth/kubelet/ca.crt"
  - name: os-kubelet-config
    hostPath:
      path: "/etc/harbor/auth/kubelet/kubeconfig.yaml"
EOF

kubectl get nodes
calicoctl status
swarm info
etcdctl-network cluster-health
etcdctl-kube cluster-health
etcdctl-docker cluster-health







mkdir -p /etc/kubernetes/applications

cat > /etc/kubernetes/applications/kube-system.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system
EOF
kubectl create -f /rootfs/etc/kubernetes/applications/kube-system.yaml



cat > /etc/kubernetes/applications/kube-dns.yaml <<EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 2
  selector:
    k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: etcd
        image: docker.io/port/system-etcd:latest
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
          requests:
            cpu: 100m
            memory: 50Mi
        command:
        - etcd
        - -data-dir
        - /var/etcd/data
        - -listen-client-urls
        - http://127.0.0.1:2379,http://127.0.0.1:4001
        - -advertise-client-urls
        - http://127.0.0.1:2379,http://127.0.0.1:4001
        - -initial-cluster-token
        - skydns-etcd
        volumeMounts:
        - name: etcd-storage
          mountPath: /var/etcd/data
      - name: kube2sky
        image: docker.io/port/system-kube2sky:latest
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        env:
          - name: OS_DOMAIN
            value: harboros.net
        volumeMounts:
        - mountPath: /etc/harbor/auth/kubelet/kubeconfig.yaml
          name: os-kubelet-config
      - name: skydns
        image: docker.io/port/system-skydns:latest
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        command:
        - /skydns
        - -machines=http://127.0.0.1:4001
        - -addr=0.0.0.0:53
        - -domain=harboros.net
        - -nameservers=8.8.8.8:53
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      volumes:
      - name: etcd-storage
        emptyDir: {}
      - name: os-kubelet-config
        hostPath:
          path: "/etc/harbor/auth/kubelet/kubeconfig.yaml"
      dnsPolicy: Default
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeDNS"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.100.0.7
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF
kubectl delete -f /rootfs/etc/kubernetes/applications/kube-dns.yaml
kubectl create -f /rootfs/etc/kubernetes/applications/kube-dns.yaml


kubectl run --image=nginx --replicas=1 nginx
swarm run -d nginx


IPA_DATA_DIR=/var/lib/harbor/freeipa/master

rm -rf /tmp/freeipa
mkdir -p /tmp/freeipa
echo "--allow-zone-overlap" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--setup-dns" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--forwarder=8.8.8.8" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--forwarder=8.8.4.4" >> ${IPA_DATA_DIR}/ipa-server-install-options
for BRIDGE_IP in 192.168.0.0/16 10.100.0.0/24 10.98.0.0/16 10.96.0.0/15; do
  # do something
  REVERSE_ZONE=$(echo ${BRIDGE_IP} | awk -F. '{print $3"." $2"."$1".in-addr.arpa."}')
  echo "--reverse-zone=${REVERSE_ZONE}" >> ${IPA_DATA_DIR}/ipa-server-install-options
done
echo "--ds-password=Password123" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--admin-password=Password123" >> ${IPA_DATA_DIR}/ipa-server-install-options


cat > /usr/local/bin/freeipa-master-daemon <<EOF
#!/bin/bash
set -e
IPA_DATA_DIR=/var/lib/harbor/freeipa/master
docker-wan stop freeipa-master || true
docker-wan kill freeipa-master || true
docker-wan rm -v freeipa-master || true
FREEIPA_MASTER_ID=\$(docker-wan run -t -d \\
 --hostname=freeipa-master.harboros.net \\
 --name=freeipa-master \\
 -v \$IPA_DATA_DIR:/data:rw \\
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \\
 --dns=8.8.8.8 \\
 -e OS_DOMAIN=harboros.net \\
 docker.io/port/ipa-server:latest)

FREEIPA_MASTER_IP=\$(docker-wan inspect --format '{{ .NetworkSettings.IPAddress }}' \${FREEIPA_MASTER_ID})

FREEIPA_MASTER_DNS_IP=\$(dig +short +time=1 +tries=20 freeipa-master.harboros.net @\$FREEIPA_MASTER_IP)
while [ -z "\$FREEIPA_MASTER_DNS_IP" ]; do
  echo "Waiting For FreeIPA DNS to respond"
  FREEIPA_MASTER_DNS_IP=\$(dig +short +time=1 +tries=20 freeipa-master.harboros.net @\$FREEIPA_MASTER_IP)
done

while [ "\$FREEIPA_MASTER_IP" != "\$FREEIPA_MASTER_DNS_IP" ]; do
  echo "Waiting for FreeIPA DNS to return expected IP"
  sleep 2s
  FREEIPA_MASTER_DNS_IP=\$(dig +short +time=1 +tries=20 freeipa-master.harboros.net @\${FREEIPA_MASTER_DNS_IP})
done


SKYDNS_CONFIG="{\\"dns_addr\\":\\"172.17.42.1:53\\", \\"ttl\\":3600, \\"nameservers\\": [\\"\${FREEIPA_MASTER_DNS_IP}:53\\"]}"

until etcdctl-network get /skydns/config; do
   echo "Waiting for ETCD"
   etcdctl-network set /skydns/config "\${SKYDNS_CONFIG}" || true
   sleep 5
done

SKYDNS_CONFIG_ETCD="\$(etcdctl-network get /skydns/config)"

if [ "\${SKYDNS_CONFIG}" != "\${SKYDNS_CONFIG_ETCD}" ]; then
   etcdctl-network set /skydns/config "\${SKYDNS_CONFIG}"
fi

EOF
chmod +x /usr/local/bin/freeipa-master-daemon


cat > /etc/systemd/system/freeipa-master.service <<EOF
[Unit]
Description=FreeIPA Master Server
After=network-online.target cloud-init.service chronyd.service docker-wan.service
Requires=docker-wan.service
Wants=network-online.target

[Service]
ExecStartPre=/usr/local/bin/freeipa-master-daemon
ExecStart=/usr/bin/docker-wan wait freeipa-master
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF




systemctl daemon-reload
systemctl restart freeipa-master
systemctl enable freeipa-master

















IPA_ADMIN_USER=admin
IPA_ADMIN_PASSWORD=Password123

#Once it is up and running check it is working by running:
dig +short -t A kube-dns.kube-system.svc.$(hostname -d). @10.100.0.7

#If the above returns your KUBE_SKYDNS_IP as an A record then SkyDNS and the Kubernetes Adapter are working, now we need to make FreeIPA use them:
FREEIPA_CONTAINER_NAME=freeipa-master
docker-wan exec ${FREEIPA_CONTAINER_NAME} /bin/bash \
-c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER} && \
    ipa dnsforwardzone-add  svc.$(hostname -d). --forwarder 10.100.0.7 && \
    ipa dnsforwardzone-add pod.$(hostname -d). --forwarder 10.100.0.7 && \
    ipa dnsrecord-add $(hostname -d) skydns --a-rec 10.100.0.7 && \
    ipa dnsrecord-add $(hostname -d). svc --ns-rec=skydns && \
    ipa dnsrecord-add $(hostname -d). pod --ns-rec=skydns && \
    kdestroy"

#Once it is up and running check it is working by running:
dig +short -t A kube-dns.kube-system.svc.$(hostname -d). @freeipa-master




kubectl label --overwrite node $(hostname --fqdn) freeipa=master
kubectl label --overwrite node $(hostname --fqdn) arch=x86
