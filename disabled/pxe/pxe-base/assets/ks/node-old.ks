text
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

selinux --enforcing

auth --useshadow --enablemd5

rootpw --lock --iscrypted locked

user --groups=wheel --name=harbor --password=password --gecos="harbor"


firewall --disabled
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate --onboot=on


services --enabled=sshd,rsyslog
# We use NetworkManager for anaconda, and Avahi doesn't make much sense in the cloud
services --disabled=network,avahi-daemon,cloud-init,cloud-init-local,cloud-config,cloud-final


bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"


zerombr
clearpart --all --initlabel --drives=sda
part /boot --size=512 --fstype="ext4"
part pv.01 --size=40960 --grow --ondisk=sda
volgroup harboros pv.01
logvol / --size=4096 --grow --fstype="xfs" --name=root --vgname=harboros
logvol /var/log --size=1024 --fstype="xfs" --name=logs --vgname=harboros

# Equivalent of %include fedora-repo.ks
ostreesetup --osname="harbor-host" --remote="harbor-host" --ref="harbor-host/7/x86_64/standard" --url="http://rpmostree.harboros.net:8012/repo/" --nogpg


reboot


%post --erroronfail

USER=harbor


# Anaconda is writing a /etc/resolv.conf from the generating environment.
# The system should start out with an empty file.
truncate -s 0 /etc/resolv.conf




# Adding the public ssh key for root
mkdir -p /root
cd /root
mkdir --mode=700 .ssh
cat >> .ssh/authorized_keys << "PUBLIC_KEY"
{{ SSH_PUBLIC_KEY }}
PUBLIC_KEY
chmod 600 .ssh/authorized_keys
chown -R root /root


# Adding the public ssh key for the user
mkdir -p /home/${USER}
cd /home/${USER}
mkdir --mode=700 .ssh
cat >> .ssh/authorized_keys << "PUBLIC_KEY"
{{ SSH_PUBLIC_KEY }}
PUBLIC_KEY
chmod 600 .ssh/authorized_keys
chown -R ${USER} /home/${USER}

# Enable passwordless sudo
sed -i 's/%wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tNOPASSWD: ALL/g' /etc/sudoers


cat > /etc/sysconfig/docker-storage-setup <<EOF
VG=docker-volumes
DATA_SIZE=10%FREE
GROWPART=true
AUTO_EXTEND_POOL=yes
POOL_AUTOEXTEND_THRESHOLD=60
POOL_AUTOEXTEND_PERCENT=20
EOF








export OS_DISTRO=HarborOS

FIXED_IP_START=10.140.0.1
FIXED_IP_PREFIXES=16
FIXED_IP_STEP=0.2.0.0

DOMAIN=port.direct
ROLE=node

SKYDNS_IP={{ SKYDNS_IP }}

INITIAL_DEV=eth0

ETCD_DEV=eth0
FLANNELD_DEV=eth0
SKYDNS_DEV=eth0
DOCKER_DEV=eth0


KUBE_PORT=8080

KUBELET_DEV=eth0
KUBELET_PORT=10250

KUBE_DOMAIN=skydns.local
KUBE_MASTER_HOST={{ KUBE_API_HOST }}

ADD_REGISTRY='--add-registry registry.harboros.net:3040'
INSECURE_REGISTRY='--insecure-registry registry.harboros.net:3040'




ETCD_DISCOVERY_TOKEN={{ ETCD_DISCOVERY_TOKEN }}
UPSTREAM_DNS=8.8.8.8


ETCD_IP=$(ip -f inet -o addr show $ETCD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
FLANNELD_IP=$(ip -f inet -o addr show $FLANNELD_DEV|cut -d\  -f 7 | cut -d/ -f 1)

DOCKER_IP=$(ip -f inet -o addr show $DOCKER_DEV|cut -d\  -f 7 | cut -d/ -f 1)
KUBELET_IP=$(ip -f inet -o addr show $KUBELET_DEV|cut -d\  -f 7 | cut -d/ -f 1)


if [[ "${ROLE}" == "master" ]]
  then
  FIXED_IP_START=10.140.0.1
elif [[ "${ROLE}" == "node" ]]
  then
  FIXED_IP_START=$(ip -f inet -o addr show $INITIAL_DEV|cut -d\  -f 7 | cut -d/ -f 1)
fi





N=1; IP_1=$(echo $FIXED_IP_START | awk -F'.' -v N=$N '{print $N}')
N=2; IP_2=$(echo $FIXED_IP_START | awk -F'.' -v N=$N '{print $N}')
N=3; IP_3=$(echo $FIXED_IP_START | awk -F'.' -v N=$N '{print $N}')
N=4; IP_4=$(echo $FIXED_IP_START | awk -F'.' -v N=$N '{print $N}')
N=1; IP_STEP_1=$(echo $FIXED_IP_STEP | awk -F'.' -v N=$N '{print $N}')
N=2; IP_STEP_2=$(echo $FIXED_IP_STEP | awk -F'.' -v N=$N '{print $N}')
N=3; IP_STEP_3=$(echo $FIXED_IP_STEP | awk -F'.' -v N=$N '{print $N}')
N=4; IP_STEP_4=$(echo $FIXED_IP_STEP | awk -F'.' -v N=$N '{print $N}')





if [ ! -f /etc/harbor-network ]; then
    echo "Config Staring"
    echo "CONFIG STARTED">> /etc/harbor-network


    echo "${OS_DISTRO}: Network Configuration"
    # initscripts don't like this file to be missing.
    cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

    echo "${OS_DISTRO}: HOSTNAME"
    if [[ "${ROLE}" == "master" ]]
      then
      HOSTNAME=master
    elif [[ "${ROLE}" == "node" ]]
      then
      HOSTNAME=${IP_1}-${IP_2}-${IP_3}-${IP_4}
    fi
    echo $HOSTNAME.$DOMAIN > /etc/hostname
    echo "$FIXED_IP_START $HOSTNAME.$DOMAIN $HOSTNAME" >> /etc/hosts


    echo "${OS_DISTRO}: INTERFACES"

    ETHERNET_DEVICES=$(nmcli -t -f GENERAL.TYPE,GENERAL.DEVICE -m tabular device show | sed -n '/ethernet/{n;p;}')



    COUNT=0
    COUNT_EXT=0
    NETWORK_SCRIPTS_LOC=/etc/sysconfig/network-scripts
    for ETHERNET_DEVICE in $ETHERNET_DEVICES; do
      ETHERNET_DEVICE_IP=$(ip -f inet -o addr show $ETHERNET_DEVICE|cut -d\  -f 7 | cut -d/ -f 1)
      if [[ ! $ETHERNET_DEVICE_IP ]]; then
        ETHERNET_DEVICE_IP=$(echo "$(expr $IP_1 + $(expr $IP_STEP_1 \* $COUNT)).$(expr $IP_2 + $(expr $IP_STEP_2 \* $COUNT)).$(expr $IP_3 + $(expr $IP_STEP_3 \* $COUNT)).$(expr $IP_4 + $(expr $IP_STEP_4 \* $COUNT))")
        ETHERNET_DEVICE_PREFIX=$FIXED_IP_PREFIXES
        ETHERNET_DEVICE_PROTO='none'
        BRIDGE_DEVICE=br${COUNT}
        COUNT=$(expr 1 + $COUNT)
      else
        ETHERNET_DEVICE_PROTO=$(ip -f inet -o addr show $ETHERNET_DEVICE|cut -d\  -f 12)
        ETHERNET_DEVICE_PREFIX=$(ip -f inet -o addr show $ETHERNET_DEVICE|cut -d\  -f 7 | cut -d/ -f 2)
        if [[ "${ROLE}" == "master" ]]; then
          if [[ "${ETHERNET_DEVICE_PROTO}" == "dynamic" ]]; then
            ETHERNET_DEVICE_PROTO='dhcp'
            BRIDGE_DEVICE=brex${COUNT_EXT}
            COUNT_EXT=$(expr 1 + $COUNT_EXT)
          else
            ETHERNET_DEVICE_PROTO='none'
            BRIDGE_DEVICE=br${COUNT}
            COUNT=$(expr 1 + $COUNT)
          fi
        elif [[ "${ROLE}" == "node" ]]; then
          if [[ "${ETHERNET_DEVICE_PROTO}" == "dynamic" ]]; then
            ETHERNET_DEVICE_PROTO='dhcp'
          else
            ETHERNET_DEVICE_PROTO='none'
          fi
          BRIDGE_DEVICE=br${COUNT}
          COUNT=$(expr 1 + $COUNT)
        fi
      fi

      if [[ "${ETHERNET_DEVICE_PROTO}" == "dhcp" ]]; then
        echo "${BRIDGE_DEVICE}: DHCP (Currently: ${ETHERNET_DEVICE_IP})"
        cat > ${NETWORK_SCRIPTS_LOC}/ifcfg-${BRIDGE_DEVICE} << EOF
DEVICE="${BRIDGE_DEVICE}"
TYPE="Bridge"
ONBOOT="yes"
DELAY=0
BOOTPROTO="${ETHERNET_DEVICE_PROTO}"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
IPV6_PRIVACY="no"
EOF
      else
        echo "${BRIDGE_DEVICE}: Static: ${ETHERNET_DEVICE_IP}"
        cat > ${NETWORK_SCRIPTS_LOC}/ifcfg-${BRIDGE_DEVICE} << EOF
DEVICE="${BRIDGE_DEVICE}"
TYPE="Bridge"
ONBOOT="yes"
BOOTPROTO="${ETHERNET_DEVICE_PROTO}"
IPADDR="${ETHERNET_DEVICE_IP}"
PREFIX="${ETHERNET_DEVICE_PREFIX}"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
IPV6_PRIVACY="no"
EOF
      fi

      echo "${ETHERNET_DEVICE}: Config device to use ${BRIDGE_DEVICE}"
      cat > ${NETWORK_SCRIPTS_LOC}/ifcfg-${ETHERNET_DEVICE} << EOF
DEVICE="${ETHERNET_DEVICE}"
ONBOOT="yes"
TYPE="Ethernet"
BOOTPROTO="none"
BRIDGE="${BRIDGE_DEVICE}"
EOF
    done
    echo "CONFIG WRIITEN">> /etc/harbor-network
    #systemctl restart network
    #nmcli connection reload
    #systemctl restart network
    echo "CONFIG COMPLETE">> /etc/harbor-network
fi






cat > /etc/systemd/system/docker-bootstrap.service << EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/docker daemon \
        -H unix:///var/run/docker-bootstrap.sock \
        -p /var/run/docker-bootstrap.pid \
        --iptables=false \
        --ip-masq=false \
        --bridge=none \
        --graph=/var/lib/docker-bootstrap \
        -s overlay \
        --dns ${SKYDNS_IP}
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF




ETCD_NAME=$HOSTNAME.$DOMAIN
cat > /etc/etcd/etcd.conf << EOF
# [member]
ETCD_NAME="$ETCD_NAME"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://127.0.0.1:2380,http://${ETCD_IP}:7001"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:2379,http://${ETCD_IP}:4001"
#
# [cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${ETCD_IP}:7001"
ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_IP}:4001"
ETCD_DISCOVERY="${ETCD_DISCOVERY_TOKEN}"
EOF







cat > /etc/systemd/system/etcd.service << EOF
[Unit]
Description=Etcd Server
After=network.target docker-bootstrap.service
Requires=network.target docker-bootstrap.service

[Service]
Type=simple
# etcd logs to the journal directly, suppress double logging
StandardOutput=null
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
TimeoutStartSec=0
RemainAfterExit=yes
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop etcd
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill etcd
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm etcd
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
      --name etcd \
      -d \
      --restart=always \
      --net=host \
      -v /etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt:ro \
      -v /var/lib/etcd/:/var/etcd/data:rw \
      gcr.io/google_containers/etcd:2.2.1 \
      /usr/local/bin/etcd \
          -name \${ETCD_NAME} \
          -initial-advertise-peer-urls \${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
          -listen-peer-urls \${ETCD_LISTEN_PEER_URLS} \
          -listen-client-urls \${ETCD_LISTEN_CLIENT_URLS} \
          -discovery \${ETCD_DISCOVERY} \
          --data-dir=/var/etcd/data

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target

EOF












################################################################################
echo "${OS_DISTRO}: Flanneld: Service"
################################################################################
cat > /etc/sysconfig/flanneld << EOF
# Flanneld configuration options

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD="http://${ETCD_IP}:4001"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_KEY="/flanneld/network"

# Any additional options that you want to pass
FLANNEL_OPTIONS="-iface=${FLANNELD_IP}"
EOF


cat > /etc/systemd/system/flanneld.service << EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target etcd.service
Before=docker.service
Requires=docker-bootstrap.service

[Service]
StandardOutput=null
TimeoutStartSec=0
RemainAfterExit=yes
Type=simple
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop flanneld
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill flanneld
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm flanneld
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
              --name flanneld \
              --restart=always \
              -d \
              --net=host \
              --privileged \
              -v /dev/net:/dev/net \
              -v /run/flannel:/run/flannel \
              quay.io/coreos/flannel:0.5.5 \
              /opt/bin/flanneld \
                  --ip-masq \
                  -etcd-endpoints=\${FLANNEL_ETCD} \
                  -etcd-prefix=\${FLANNEL_ETCD_KEY} \
                  \$FLANNEL_OPTIONS
ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker

Restart=on-failure
RestartSec=10

[Install]
RequiredBy=docker.service
EOF


# This detects that flanneld is reday to go
cat > /etc/systemd/system/flanneld.path << EOF
[Path]
PathExists=/run/flannel/subnet.env
Unit=docker.service

[Install]
WantedBy=multi-user.target
EOF



mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/10-flanneld-network.conf << EOF
[Unit]
After=flanneld.service flanneld.path
Requires=flanneld.service flanneld.path

[Service]
TimeoutStartSec=0
EnvironmentFile=/run/flannel/subnet.env
EnvironmentFile=/etc/sysconfig/docker
EnvironmentFile=/etc/sysconfig/docker-storage
ExecStartPre=-/usr/sbin/ip link del docker0
ExecStart=
ExecStart=/usr/bin/docker \
          daemon \
          --bip=\${FLANNEL_SUBNET} \
          --mtu=\${FLANNEL_MTU} \
          \$OPTIONS \
          \$DOCKER_STORAGE_OPTIONS \
          \$BLOCK_REGISTRY \
          \$INSECURE_REGISTRY
Restart=always
RestartSec=10

EOF










################################################################################
echo "${OS_DISTRO}: Docker: Config"
################################################################################

cat > /etc/sysconfig/docker <<EOF
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
#OPTIONS='--selinux-enabled --dns ${SKYDNS_IP} -H tcp://${DOCKER_IP}:2375 -H unix:///var/run/docker.sock'
OPTIONS='--dns ${SKYDNS_IP} -H tcp://${DOCKER_IP}:2375 -H unix:///var/run/docker.sock -cluster-store=etcd://127.0.0.1:2379 --cluster-advertise=${DOCKER_IP}:2375'

DOCKER_CERT_PATH=/etc/docker

# If you want to add your own registry to be used for docker search and docker
# pull use the ADD_REGISTRY option to list a set of registries, each prepended
# with --add-registry flag. The first registry added will be the first registry
# searched.
ADD_REGISTRY='$ADD_REGISTRY'

# If you want to block registries from being used, uncomment the BLOCK_REGISTRY
# option and give it a set of registries, each prepended with --block-registry
# flag. For example adding docker.io will stop users from downloading images
# from docker.io
# BLOCK_REGISTRY='--block-registry'

# If you have a registry secured with https but do not have proper certs
# distributed, you can tell docker to not look for full authorization by
# adding the registry to the INSECURE_REGISTRY line and uncommenting it.
INSECURE_REGISTRY='$INSECURE_REGISTRY'

# On an SELinux system, if you remove the --selinux-enabled option, you
# also need to turn on the docker_transition_unconfined boolean.
# setsebool -P docker_transition_unconfined 1

# Location used for temporary files, such as those created by
# docker load and build operations. Default is /var/lib/docker/tmp
# Can be overriden by setting the following environment variable.
# DOCKER_TMPDIR=/var/tmp

# Controls the /etc/cron.daily/docker-logrotate cron job status.
# To disable, uncomment the line below.
# LOGROTATE=false
EOF



cat > /etc/sysconfig/docker-storage <<EOF
DOCKER_STORAGE_OPTIONS=--storage-driver overlay
EOF




################################################################################
echo "${OS_DISTRO}: Docker Swarm: Agent"
################################################################################
cat > /etc/systemd/system/docker-swarm.service << EOF
[Unit]
Description=HarborOS: Docker Swarm Service
After=etcd.service \
      docker.service
Requires=etcd.service \
      docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill swarm-agent
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm swarm-agent
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock pull swarm
ExecStartPre=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run -d \
                            --net host \
                            --name swarm-agent \
                            swarm join --addr=${DOCKER_IP}:2375 etcd://${ETCD_IP}:4001/dockerswarm
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock logs -f swarm-agent
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop swarm-agent

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF






################################################################################
echo "${OS_DISTRO}: kubernetes Config"
################################################################################
mkdir -p /etc/kubernetes

cat > /etc/kubernetes/deploy.env << EOF
KUBERNETES_IMAGE=gcr.io/google_containers/hyperkube:v1.1.2
KUBESKY_IMAGE=gcr.io/google_containers/kube2sky:1.12
EOF

cat > /etc/kubernetes/config <<EOF
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
KUBE_LOG_LEVEL="--v=2"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow_privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=http://${KUBE_MASTER_HOST}:${KUBE_PORT}"
EOF


cat > /etc/kubernetes/kubelet <<EOF
###
# kubernetes kubelet (minion) config

# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=${KUBELET_IP}"

# The port for the info server to serve on
# KUBELET_PORT="--port=${KUBELET_PORT}"

# You may leave this blank to use the actual hostname
#KUBELET_HOSTNAME="--hostname_override=${KUBELET_HOSTNAME}"

# location of the api-server
KUBELET_API_SERVER="--api_servers=http://${KUBE_MASTER_HOST}:${KUBE_PORT}"

# Add your own!
KUBELET_ARGS="--cluster-dns=${SKYDNS_IP} --cluster-domain=${KUBE_DOMAIN}"
EOF




################################################################################
echo "${OS_DISTRO}: Kubelet Server"
################################################################################
cat > /etc/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

After=etcd.service docker-bootstrap.service
Requires=etcd.service docker-bootstrap.service

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
EnvironmentFile=/etc/kubernetes/deploy.env

ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill kubelet
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm kubelet
ExecStartPre=/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
            --name=kubelet \
            --net=host \
            --pid=host \
            --privileged \
            --restart=always \
            -d \
            -v /etc/os-release:/etc/os-release:ro \
            -v /sys:/sys:ro \
            -v /var/run:/var/run:rw \
            -v /:/rootfs:ro \
            -v /dev:/dev \
            -v /var/lib/docker/:/var/lib/docker:rw \
            -v /var/lib/kubelet/:/var/lib/kubelet:rw \
            \$KUBERNETES_IMAGE /hyperkube kubelet \
            	    \$KUBE_LOGTOSTDERR \
            	    \$KUBE_LOG_LEVEL \
            	    \$KUBELET_API_SERVER \
            	    \$KUBELET_ADDRESS \
            	    \$KUBELET_PORT \
            	    \$KUBELET_HOSTNAME \
            	    \$KUBE_ALLOW_PRIV \
            	    \$KUBELET_ARGS \
                  --containerized
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock logs -f kubelet
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop kubelet

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


################################################################################
echo "${OS_DISTRO}: Kubelet Proxy"
################################################################################
cat > /etc/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

After=etcd.service docker-bootstrap.service
Requires=etcd.service docker-bootstrap.service

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/proxy
EnvironmentFile=-/etc/kubernetes/deploy.env

ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill kube-proxy
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm kube-proxy
ExecStartPre=/bin/docker -H unix:///var/run/docker-bootstrap.sock run  -d \
            --net='host' \
            --privileged \
            --name=kube-proxy \
            -v /etc/ssl/certs:/etc/ssl/certs \
            -v /etc/kubernetes/ssl:/etc/kubernetes/ssl \
            \$KUBERNETES_IMAGE /hyperkube proxy \
                \$KUBE_LOGTOSTDERR \
          	    \$KUBE_LOG_LEVEL \
          	    \$KUBE_MASTER \
          	    \$KUBE_PROXY_ARGS
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock logs -f kube-proxy
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop kube-proxy

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF



################################################################################
echo "${OS_DISTRO}: IPA Registration Service"
################################################################################
IPA_CLIENT_DEV=eth0
IPA_CLIENT_IP=$(ip -f inet -o addr show $IPA_CLIENT_DEV|cut -d\  -f 7 | cut -d/ -f 1)
mkdir -p /etc/freeipa
cat > /etc/freeipa/credentials-client-provisioning.env <<EOF
IPA_CLIENT_IP="${IPA_CLIENT_IP}"
EOF

cat > /etc/systemd/system/ipa-register.service << EOF
[Unit]
Description=IPA Registration Service
After=docker.service

[Service]
TimeoutStartSec=240
EnvironmentFile=/etc/freeipa/credentials-client-provisioning.env
RemainAfterExit=True

ExecStartPre=-/sbin/ipa-client-install --uninstall --unattended
ExecStart=/sbin/ipa-client-install \
                  -p admin \
                  -w Password!23 \
                  --ip-address=$IPA_CLIENT_IP \
                  --no-ntp \
                  --force-join --unattended

ExecStop=/sbin/ipa-client-install --uninstall --unattended

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF








################################################################################
echo "${OS_DISTRO}: Storage"
################################################################################



cat > /etc/systemd/system/harbor-sysinfo.service << EOF
[Unit]
Description=HarborOS Sysinfo Reporter
After=etcd.service docker.service
Requires=etcd.service docker.service

[Service]
TimeoutStartSec=300
RemainAfterExit=true
ExecStartPre=-/bin/docker pull registry.harboros.net:3040/harboros/utils-discs:latest
ExecStartPre=-/bin/docker rm harbor-reporter
ExecStart=/bin/docker run -d --net=host \
                  -v /dev:/dev \
                  -v /tmp/harbor:/tmp/harbor \
                  --name harbor-reporter \
                  registry.harboros.net:3040/harboros/utils-discs:latest /opt/harbor/reporter
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF


cat > /etc/systemd/system/harbor-update.path << EOF
[Unit]
Description=Harbor System Config Update Service

[Path]
PathChanged=/tmp/harbor/harbor-update

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/harbor-update.service << EOF
[Unit]
Description=Harbor System Config Update Service

[Service]
ExecStart=/var/usrlocal/bin/harbor-update.sh
Type=oneshot
EOF

cat > /var/usrlocal/bin/harbor-update.sh << EOF
#!/bin/bash
script=\$(cat /tmp/harbor/harbor-update)
exec /tmp/harbor/assets/\${script}
EOF
chmod +x /var/usrlocal/bin/harbor-update.sh



cat > /etc/systemd/system/harbor-mounter.path << EOF
[Unit]
Description=HarborOS Mounter

[Path]
PathChanged=/tmp/harbor/harbor-mount

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/harbor-mounter.service << EOF
[Unit]
Description=HarborOS Mounter
After=etcd.service docker.service
Requires=etcd.service docker.service harbor-update

[Service]
TimeoutStartSec=300
Type=oneshot
ExecStartPre=-/bin/docker pull registry.harboros.net:3040/harboros/utils-discs:latest
ExecStartPre=-/bin/docker stop harbor-mounter
ExecStartPre=-/bin/docker kill harbor-mounter
ExecStartPre=-/bin/docker rm harbor-mounter
ExecStart=/bin/docker run -d -v /tmp/harbor:/tmp/harbor \
                  --name harbor-mounter \
                  -e SCRIPT=mount \
                  registry.harboros.net:3040/harboros/utils-discs:latest

[Install]
WantedBy=multi-user.target

EOF


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



ACTION=enable
systemctl ${ACTION} docker-bootstrap
systemctl ${ACTION} ipa-register
systemctl ${ACTION} etcd
systemctl mask docker-storage-setup || echo "already disabled"
systemctl ${ACTION} docker
systemctl ${ACTION} docker-swarm
systemctl ${ACTION} harbor-sysinfo
systemctl ${ACTION} harbor-update.path
systemctl ${ACTION} harbor-mounter.path
systemctl ${ACTION} kubelet
systemctl ${ACTION} kube-proxy


# older versions of livecd-tools do not follow "rootpw --lock" line above
# https://bugzilla.redhat.com/show_bug.cgi?id=964299
passwd -l root
userdel -r centos || echo "no centos user"


# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics we, like CentOS
# are differing from the Fedora default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# Fixing the locale settings
cat > /etc/environment << EOF
LANG="en_US.utf-8"
LC_ALL="en_US.utf-8"
EOF

%end
