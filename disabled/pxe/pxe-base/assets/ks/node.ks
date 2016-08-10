text
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

selinux --enforcing

auth --useshadow --enablemd5

rootpw --lock --iscrypted locked

user --groups=wheel --name=harbor --lock --iscrypted locked --gecos="harbor"


firewall --disabled
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate --onboot=on


services --enabled=sshd,rsyslog
# We use NetworkManager for anaconda, and Avahi doesn't make much sense in the cloud
services --disabled=network,avahi-daemon,cloud-init,cloud-init-local,cloud-config,cloud-final


bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"



# Partition table
clearpart --linux --drives=sda

part /boot --size=1024 --ondisk sda
part pv.01 --size=1    --ondisk sda --grow
volgroup vg1 pv.01
logvol /    --vgname=vg1 --size=10000  --grow --name=root --fstype=xfs
logvol swap --vgname=vg1 --recommended --name=swap --fstype=swap
ignoredisk --only-use=sda


# Equivalent of %include fedora-repo.ks
ostreesetup --osname="harbor-host" --remote="harbor-host" --ref="harbor-host/7/x86_64/standard" --url="http://rpmostree.harboros.net:8012/repo/" --nogpg


reboot





%post --erroronfail

USER=harbor

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




export OS_DISTRO=HarborOS

FIXED_IP_START=10.140.0.1
FIXED_IP_PREFIXES=16
FIXED_IP_STEP=0.2.0.0

DOMAIN=port.direct
ROLE=node

MASTER_SKYDNS_IP={{ SKYDNS_IP }}

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

INSECURE_REGISTRY='--insecure-registry registry.harboros.net:3040'

ETCD_DISCOVERY_TOKEN={{ ETCD_DISCOVERY_TOKEN }}


if [[ "${ROLE}" == "master" ]]
  then
  UPSTREAM_DNS=8.8.8.8
elif [[ "${ROLE}" == "node" ]]
  then
  UPSTREAM_DNS=$MASTER_SKYDNS_IP
fi



ETCD_IP=$(ip -f inet -o addr show $ETCD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
FLANNELD_IP=$(ip -f inet -o addr show $FLANNELD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
DOCKER_IP=$(ip -f inet -o addr show $DOCKER_DEV|cut -d\  -f 7 | cut -d/ -f 1)
KUBELET_IP=$(ip -f inet -o addr show $KUBELET_DEV|cut -d\  -f 7 | cut -d/ -f 1)
SKYDNS_IP=$(ip -f inet -o addr show $SKYDNS_DEV|cut -d\  -f 7 | cut -d/ -f 1)





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













################################################################################
echo "${OS_DISTRO}: IPA Registration Service"
################################################################################
IPA_CLIENT_DEV=eth0
IPA_CLIENT_IP=$(ip -f inet -o addr show $IPA_CLIENT_DEV|cut -d\  -f 7 | cut -d/ -f 1)
mkdir -p /etc/freeipa
cat > /etc/freeipa/credentials-client-provisioning.env <<EOF
IPA_CLIENT_IP=${IPA_CLIENT_IP}
EOF

cat > /etc/systemd/system/ipa-register.service << EOF
[Unit]
Description=IPA Registration Service
After=skydns.service

[Service]
TimeoutStartSec=240
TimeoutStopSec=240
EnvironmentFile=/etc/freeipa/credentials-client-provisioning.env
RemainAfterExit=True

ExecStartPre=-/sbin/ipa-client-install --uninstall --unattended
ExecStart=/sbin/ipa-client-install \
                  -p admin \
                  -w 'Password!23' \
                  --ip-address=${IPA_CLIENT_IP} \
                  --no-ntp \
                  --force-join --unattended

ExecStop=/sbin/ipa-client-install --uninstall --unattended

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF








cat > /etc/systemd/system/docker-bootstrap.service << EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/docker daemon \
        --log-driver=journald \
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
mkdir -p /etc/etcd
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
Requires=docker-bootstrap.service

[Service]
Type=simple
# etcd logs to the journal directly, suppress double logging
EnvironmentFile=-/etc/etcd/etcd.conf
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop etcd
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill etcd
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm etcd
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
      --name etcd \
      --net=host \
      -v /etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt:ro \
      gcr.io/google_containers/etcd:2.2.1 \
      /usr/local/bin/etcd \
          -name \${ETCD_NAME} \
          -initial-advertise-peer-urls \${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
          --advertise-client-urls \${ETCD_ADVERTISE_CLIENT_URLS} \
          -listen-peer-urls \${ETCD_LISTEN_PEER_URLS} \
          -listen-client-urls \${ETCD_LISTEN_CLIENT_URLS} \
          -discovery \${ETCD_DISCOVERY} \
          --data-dir=/var/etcd/data

ExecStop=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop etcd
ExecStop=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill etcd
ExecStop=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm etcd

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF




cat > /etc/systemd/system/ovs.service << EOF
[Unit]
Description=OpenVSwitch
After=network.target docker-bootstrap.service
Before=docker.service
Requires=docker-bootstrap.service

[Service]
StandardOutput=null
TimeoutStartSec=0
RemainAfterExit=yes
Type=simple
ExecStartPre=-/usr/sbin/modprobe openvswitch
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock pull docker.io/harboros/ovs:latest
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop ovs
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill ovs
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm ovs
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
              --name ovs \
              --restart=always \
              --net=host \
              --privileged \
              --cap-add NET_ADMIN \
              -v /dev/net:/dev/net \
              -v /var/run/openvswitch:/usr/local/var/run/openvswitch \
              docker.io/harboros/ovs:latest
ExecStop=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop ovs
ExecStop=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill ovs
ExecStop=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm ovs

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF



SKYDNS_IMAGE=gcr.io/google_containers/skydns:2015-03-11-001
cat > /etc/systemd/system/skydns.service << EOF
[Unit]
Description=HarborOS: Skydns Server
After=docker-bootstrap.service
Requires=docker-bootstrap.service

[Service]
TimeoutStartSec=0
Restart=always
RestartSec=10

ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop skydns
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill skydns
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm skydns

ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
              --name skydns \
              --net=host \
              ${SKYDNS_IMAGE} \
                    -addr=${SKYDNS_IP}:53 \
                    -machines=http://127.0.0.1:2379 \
                    -nameservers=$UPSTREAM_DNS:53

ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop skydns
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill skydns
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm skydns

[Install]
WantedBy=multi-user.target
EOF



cat > /etc/systemd/system/docker.service << EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker-bootstrap.service
Requires=docker-bootstrap.service

[Service]
Type=simple
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock pull docker.io/harboros/utils-network:latest
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop docker-register
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill docker-register
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm docker-register
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop docker-network
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill docker-network
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm docker-network
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop ovs-harbor-bridge-init
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill ovs-harbor-bridge-init
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm ovs-harbor-bridge-init
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop ovs-harbor-bridge
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill ovs-harbor-bridge
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm ovs-harbor-bridge
ExecStartPre=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
                --net=host \
                --name docker-register \
                -v /var/run/docker-bootstrap.sock:/var/run/docker.sock \
                docker.io/harboros/utils-network:latest /bin/register
ExecStartPre=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
                --net=host \
                --name docker-network \
                -v /var/run/docker-bootstrap.sock:/var/run/docker.sock \
                docker.io/harboros/utils-network:latest /bin/prep-docker
ExecStartPre=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
                --net=host \
                --name ovs-harbor-bridge-init \
                -v /var/run/docker-bootstrap.sock:/var/run/docker.sock \
                docker.io/harboros/utils-network:latest /bin/update-ovs
ExecStartPre=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
                -d \
                --restart=always \
                --net=host \
                --name ovs-harbor-bridge \
                -v /var/run/docker-bootstrap.sock:/var/run/docker.sock \
                docker.io/harboros/utils-network:latest /bin/etcd-monitor
ExecStart=/var/usrlocal/bin/docker-daemon.sh

MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


cat > /var/usrlocal/bin/docker-daemon.sh << EOF
#!/bin/bash
set -e
ETCD_DEV=br0
DOCKER_DEV=br0
SKYDNS_DEV=br0


INSECURE_REGISTRY='--insecure-registry registry.harboros.net:3040'

DOCKER_CMD='docker -H unix:///var/run/docker-bootstrap.sock'
ETCD_CONTAINER=etcd
ETCDCTL_COMMAND="\$DOCKER_CMD exec \$ETCD_CONTAINER etcdctl"
ETCD_IP=\$(ip -f inet -o addr show \$ETCD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
ETCD_NAME=\$(hostname --fqdn)
DOCKER_IP=\$(ip -f inet -o addr show \$DOCKER_DEV|cut -d\  -f 7 | cut -d/ -f 1)
SKYDNS_IP=\$(ip -f inet -o addr show \$SKYDNS_DEV|cut -d\  -f 7 | cut -d/ -f 1)
HOST_DOCKER_SUBNET=\$(\$ETCDCTL_COMMAND get /ovs/network/nodes/\$ETCD_NAME)

exec docker daemon \
        --log-driver=json-file \
	      --log-opt max-size=1m \
        --log-opt max-file=2 \
        --bridge=docker0 \
        --mtu=1462 \
        --fixed-cidr=\${HOST_DOCKER_SUBNET} \
        --dns \${SKYDNS_IP} \
        -H unix:///var/run/docker.sock \
        -H tcp://${DOCKER_IP}:2375 \
        --cluster-store=etcd://127.0.0.1:2379 \
        --cluster-advertise=\${DOCKER_IP}:2375 \
        --storage-driver overlay \$INSECURE_REGISTRY
EOF
chmod +x /var/usrlocal/bin/docker-daemon.sh

cat > /var/usrlocal/bin/harbor-docker << EOF
#!/bin/sh
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock \$@
EOF
chmod +x /var/usrlocal/bin/harbor-docker


cat > /var/usrlocal/bin/etcdctl << EOF
#!/bin/sh
set -e
harbor-docker exec etcd etcdctl \$@
EOF
chmod +x /var/usrlocal/bin/etcdctl




mkdir -p /etc/kubernetes
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
KUBE_LOG_LEVEL="--v=3"

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
KUBELET_PORT="--port=${KUBELET_PORT}"

# You may leave this blank to use the actual hostname
KUBELET_HOSTNAME="--hostname_override=$HOSTNAME.$DOMAIN"

# location of the api-server
KUBELET_API_SERVER="--api_servers=http://${KUBE_MASTER_HOST}:${KUBE_PORT}"

# Add your own!
KUBELET_ARGS="--cluster-dns=${SKYDNS_IP} --cluster-domain=${KUBE_DOMAIN}"
EOF






cat > /etc/kubernetes/deploy.env <<EOF
KUBERNETES_IMAGE=gcr.io/google_containers/hyperkube:v1.1.7
KUBESKY_IMAGE=gcr.io/google_containers/kube2sky:1.12
EOF

cat > /etc/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

After=docker-bootstrap.service
Requires=docker-bootstrap.service

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
EnvironmentFile=/etc/kubernetes/deploy.env

ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill kubelet
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm kubelet
ExecStart=/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
            --name=kubelet \
            --net=host \
            --pid=host \
            --privileged \
            --restart=always \
            -v /sys:/sys:ro \
            -v /var/run:/var/run:rw \
            -v /:/rootfs:ro \
            -v /dev:/dev \
            -v /var/lib/docker/:/var/lib/docker:rw \
            -v /var/lib/kubelet/:/var/lib/kubelet:rw \
            -v /etc/os-release:/etc/os-release:ro \
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
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop kubelet
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm kubelet

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF


cat > /etc/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

After=docker-bootstrap.service
Requires=docker-bootstrap.service

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/proxy
EnvironmentFile=-/etc/kubernetes/deploy.env

ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill kube-proxy
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm kube-proxy
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
            --net='host' \
            --privileged \
            --name=kube-proxy \
            --restart=always \
            -v /etc/ssl/certs:/etc/ssl/certs \
            -v /etc/kubernetes/ssl:/etc/kubernetes/ssl \
            \$KUBERNETES_IMAGE /hyperkube proxy \
                \$KUBE_LOGTOSTDERR \
          	    \$KUBE_LOG_LEVEL \
          	    \$KUBE_MASTER \
          	    \$KUBE_PROXY_ARGS
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop kube-proxy
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm kube-proxy

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF




cat > /etc/systemd/system/harbor-sysinfo.service << EOF
[Unit]
Description=HarborOS Sysinfo Reporter
After=etcd.service docker-bootstrap.service
Requires=etcd.service docker-bootstrap.service

[Service]
TimeoutStartSec=300
RemainAfterExit=true
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock pull registry.harboros.net:3040/harboros/utils-discs:latest
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm harbor-reporter
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run --net=host \
                  -v /dev:/dev \
                  -v /tmp/harbor:/tmp/harbor \
                  --name harbor-reporter \
                  docker.io/harboros/utils-discs:latest /opt/harbor/reporter
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF









cat > /etc/systemd/system/swarm.service << EOF
[Unit]
Description=HarborOS: Docker Swarm Service
After=etcd.service docker.service
Requires=etcd.service docker.service

[Service]
TimeoutStartSec=0

ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill swarm
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm swarm
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run --net=host \
          --name swarm \
          --restart always \
          docker.io/swarm:latest join \
              --addr=${DOCKER_IP}:2375 \
              etcd://127.0.0.1:2379/dockerswarm
ExecStop=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop swarm

Restart=always
RestartSec=10

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
After=etcd.service docker-bootstrap.service
Requires=docker-bootstrap.service

[Service]
TimeoutStartSec=0
Type=oneshot
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock docker.io/harboros/utils-discs:latest
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock stop harbor-mounter
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock kill harbor-mounter
ExecStartPre=-/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock rm harbor-mounter
ExecStart=/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock run \
                  -v /tmp/harbor:/tmp/harbor \
                  --name harbor-mounter \
                  -e SCRIPT=mount \
                  docker.io/harboros/utils-discs:latest

[Install]
WantedBy=multi-user.target


EOF



ACTION=enable
systemctl mask docker.socket
systemctl ${ACTION} docker-bootstrap
systemctl ${ACTION} etcd
systemctl ${ACTION} ovs
systemctl ${ACTION} skydns
systemctl ${ACTION} docker
systemctl ${ACTION} kubelet
systemctl ${ACTION} kube-proxy
systemctl ${ACTION} ipa-register
systemctl ${ACTION} harbor-sysinfo
systemctl ${ACTION} swarm
systemctl ${ACTION} harbor-update.path
systemctl ${ACTION} harbor-mounter.path
systemctl ${ACTION} harbor-mounter.service

















%end
