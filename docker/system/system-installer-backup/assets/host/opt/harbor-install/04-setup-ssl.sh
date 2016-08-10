#!/bin/sh
export PATH=/usr/local/bin:${PATH}
source /etc/openstack/openstack.env

MASTER_IP=$(ip -f inet -o addr show br0|cut -d\  -f 7 | cut -d/  -f 1)

cat > /etc/systemd/system/puppet-master.service <<EOF
[Unit]
Description=Puppet Server
After=docker-ipa.service docker.service
Requires=docker-ipa.service docker.service

[Service]
StandardOutput=null
TimeoutStartSec=0

ExecStartPre=-/usr/bin/docker stop puppet-master
ExecStartPre=-/usr/bin/docker kill puppet-master
ExecStartPre=-/usr/bin/docker rm -v puppet-master
ExecStartPre=/usr/bin/docker run -p 8140:8140 -d -t \
                        --name puppet-master \
                        --hostname puppet-master.$(hostname -d) \
                        --privileged \
                        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                        -v /etc/httpd \
                        -v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
                        -v /var/lib/harbor/foreman/puppet/ssl:/var/lib/puppet/ssl:rw \
                        -v /var/lib/harbor/foreman/pod:/var/pod:rw \
                        port/foreman-puppet:latest /sbin/init
ExecStart=/usr/bin/docker logs -f puppet-master
ExecStop=/usr/bin/docker stop puppet-master
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl restart docker-bridge
systemctl restart docker
systemctl start puppet-master
systemctl enable puppet-master


################################################################################
echo "${OS_DISTRO}: Setting up puppet agent"
################################################################################
cat > /etc/puppet/puppet.conf <<EOF
[main]
    # define the fqdn of the puppet master
    server = puppet-master.$(hostname -d)

    # The Puppet log directory.
    # The default value is '$vardir/log'.
    logdir = /var/log/puppet

    # Where Puppet PID files are kept.
    # The default value is '$vardir/run'.
    rundir = /var/run/puppet

    # Where SSL certificates are kept.
    # The default value is '$confdir/ssl'.
    ssldir = \$vardir/ssl

[agent]
    # The file in which puppetd stores a list of the classes
    # associated with the retrieved configuratiion.  Can be loaded in
    # the separate ``puppet`` executable using the ``--loadclasses``
    # option.
    # The default value is '\$confdir/classes.txt'.
    classfile = \$vardir/classes.txt

    # Where puppetd caches the local configuration.  An
    # extension indicating the cache format is added automatically.
    # The default value is '\$confdir/localconfig'.
    localconfig = \$vardir/localconfig
EOF

puppet agent --test || true
systemctl start puppet
systemctl enable puppet




################################################################################
echo "${OS_DISTRO}: Link puppet ssl cert/key and ca to locations to be used by kube later"
################################################################################
SVC_HOST_NAME=$(hostname -s)
SVC_AUTH_ROOT_HOST=/etc/harbor/auth
PUPPET_SSL_DIR=/var/lib/puppet/ssl

HOST_SVC_KEY_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key
HOST_SVC_CRT_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt
HOST_SVC_CA_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt

mkdir -p ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}
cat ${PUPPET_SSL_DIR}/certs/ca.pem > ${HOST_SVC_CA_LOC}
cat ${PUPPET_SSL_DIR}/certs/$(hostname -f).pem > ${HOST_SVC_CRT_LOC}
cat ${PUPPET_SSL_DIR}/private_keys/$(hostname -f).pem > ${HOST_SVC_KEY_LOC}
mkdir -p ${SVC_AUTH_ROOT_HOST}/host/messaging
cat ${HOST_SVC_KEY_LOC} > ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging.key
cat ${HOST_SVC_CRT_LOC} > ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging.crt
cat ${HOST_SVC_CA_LOC} > ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging-ca.crt
mkdir -p ${SVC_AUTH_ROOT_HOST}/host/database
cat ${HOST_SVC_KEY_LOC} > ${SVC_AUTH_ROOT_HOST}/host/database/database.key
cat ${HOST_SVC_CRT_LOC} > ${SVC_AUTH_ROOT_HOST}/host/database/database.crt
cat ${HOST_SVC_CA_LOC} > ${SVC_AUTH_ROOT_HOST}/host/database/database-ca.crt



################################################################################
echo "${OS_DISTRO}: Generate Service Certs for Kube and register dns with ipa"
################################################################################
MASTER_IP=$(ip -f inet -o addr show br0|cut -d\  -f 7 | cut -d/  -f 1)
generate_service_cirt () {
 SVC_HOST_NAME=$1
 SVC_HOST_IP=$2

 FREEIPA_CONTAINER_NAME=freeipa-master
 SVC_AUTH_ROOT_CONTAINER=/data/harbor/auth
 SVC_AUTH_ROOT_HOST=/etc/harbor/auth
 mkdir -p ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}
 KUBE_SVC_KEY_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key
 KUBE_SVC_CRT_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt
 KUBE_SVC_CA_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt
 ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER}"
 ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d) ${SVC_HOST_NAME} --a-rec=${SVC_HOST_IP}"
 ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add ${SVC_HOST_NAME}.$(hostname -d) --desc=\"kubernetes service endpoint\" --location=\$(hostname --fqdn)"
 ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add-managedby ${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"

 ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add kube/${SVC_HOST_NAME}.$(hostname -d)"
 ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add-host kube/${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"
 ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"
 docker exec -it puppet-master puppet cert generate ${SVC_HOST_NAME}.$(hostname -d)
 sleep 5s
 docker exec -it puppet-master cat /var/lib/puppet/ssl/private_keys/${SVC_HOST_NAME}.$(hostname -d).pem > ${KUBE_SVC_KEY_LOC}
 docker exec -it puppet-master cat /var/lib/puppet/ssl/certs/${SVC_HOST_NAME}.$(hostname -d).pem > ${KUBE_SVC_CRT_LOC}
 docker exec -it puppet-master cat /var/lib/puppet/ssl/certs/ca.pem > ${KUBE_SVC_CA_LOC}
}

#First generate the certificate and key pair for the kubernetes api server:
generate_service_cirt kubernetes ${MASTER_IP}

#And now we will generate the certificate and key pair for the kubernetes services:
generate_service_cirt kubelet ${MASTER_IP}





#From the certificates we have generated, we can produce a kubeconfig file that kubernetes components will use to authenticate against the api server:
SVC_HOST_NAME=kubelet
FREEIPA_CONTAINER_NAME=freeipa-master
SVC_AUTH_ROOT_HOST=/etc/harbor/auth
cat > ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    client-certificate-data: $( cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt | base64 --wrap=0)
    client-key-data: $( cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key | base64 --wrap=0)
clusters:
- name: $(echo $OS_DOMAIN | tr '.' '-')
  cluster:
    certificate-authority-data: $(cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt | base64 --wrap=0)
contexts:
- context:
    cluster: $(echo $OS_DOMAIN | tr '.' '-')
    user: kubelet
  name: service-account-context
current-context: service-account-context
EOF

# Copy the kubeconfig to the IPA server storage for use by the pxe provisioner and other services.

IPA_DATA_DIR=/var/lib/freeipa-master
mkdir -p $IPA_DATA_DIR/harbor/auth/kubelet
cp -f ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/kubeconfig.yaml $IPA_DATA_DIR/harbor/auth/kubelet/kubeconfig.yaml


#Finally we set the hosts file on the master server to resolve kubernetes to the approriate ip:
source /etc/openstack/openstack.env
MASTER_IP=$(ip -f inet -o addr show br0|cut -d\  -f 7 | cut -d/  -f 1)
echo "${MASTER_IP} kubernetes.$(hostname -d) kubernetes" >> /etc/hosts



















cat > /etc/systemd/system/foreman-master.service <<EOF
[Unit]
Description=Foreman Master Server
After=docker-ipa.service docker.service puppet-master.service
Requires=docker-ipa.service docker.service

[Service]
StandardOutput=null
TimeoutStartSec=0

ExecStartPre=-/usr/bin/docker stop foreman-master
ExecStartPre=-/usr/bin/docker kill foreman-master
ExecStartPre=-/usr/bin/docker rm -v foreman-master
ExecStartPre=/usr/bin/docker run -p 444:443 -d -t \
                        --name foreman-master \
                        --hostname foreman.$(hostname -d) \
                        --privileged \
                        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                        -v /etc/httpd \
                        -v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
                        -v /var/lib/harbor/foreman/pod:/var/pod:rw \
                        -v /var/lib/harbor/foreman/ssh:/usr/share/foreman-proxy/.ssh/:rw \
                        -v /var/lib/harbor/foreman/dynflow:/var/lib/foreman-proxy/dynflow/:rw \
                        port/foreman-master:latest /sbin/init
ExecStart=/usr/bin/docker logs -f foreman-master
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF




for BRIDGE_DEVICE in br0 br1 br2; do
  cat > /etc/systemd/system/foreman-proxy-${BRIDGE_DEVICE}.service <<EOF
[Unit]
Description=Foreman Smart Proxy for ${BRIDGE_DEVICE}
After=docker-ipa.service docker.service
Requires=docker-ipa.service docker.service

[Service]
StandardOutput=null
TimeoutStartSec=0

ExecStartPre=-/usr/bin/docker stop foreman-proxy-${BRIDGE_DEVICE}
ExecStartPre=-/usr/bin/docker kill foreman-proxy-${BRIDGE_DEVICE}
ExecStartPre=-/usr/bin/docker rm -v foreman-proxy-${BRIDGE_DEVICE}
ExecStartPre=/usr/local/bin/foreman-proxy-${BRIDGE_DEVICE}
ExecStart=/usr/bin/docker logs -f foreman-proxy-${BRIDGE_DEVICE}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  cat > /usr/local/bin/foreman-proxy-${BRIDGE_DEVICE} <<EOF
BRIDGE_IP=\$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
IP=$(echo \${BRIDGE_IP} | awk -F. '{print $1"."$2"."$3".10"}')
docker run -d -t \
--name foreman-proxy-\${BRIDGE_DEVICE} \
--hostname foreman-proxy-\${BRIDGE_DEVICE}.port.direct \
--privileged \
-v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
-v /var/lib/harbor/foreman/pod:/var/pod:rw \
-v /var/lib/harbor/foreman/proxy-\${BRIDGE_DEVICE}/tftpboot:/var/lib/tftpboot:rw \
-v /var/lib/harbor/foreman/proxy-\${BRIDGE_DEVICE}/puppet:/var/lib/puppet/ssl:rw \
port/foreman-proxy:latest /sbin/init
pipework \${BRIDGE_DEVICE} -i \${BRIDGE_DEVICE} -l dhcp_\${BRIDGE_DEVICE} foreman-proxy-\${BRIDGE_DEVICE} \${IP}/16
EOF
chmod +x /usr/local/bin/foreman-proxy-${BRIDGE_DEVICE}
done


docker run -p 8140:8140 -d -t \
--name puppet-master \
--hostname puppet-master.port.direct \
--privileged \
-v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
-v /var/lib/harbor/foreman/puppet/ssl:/var/lib/puppet/ssl:rw \
-v /var/lib/harbor/foreman/pod:/var/pod:rw \
port/foreman-puppet:latest /sbin/init
docker logs -f puppet-master
docker exec -it puppet-master bash


docker run -p 444:443 -d -t \
--name foreman-master \
--hostname foreman.port.direct \
--privileged \
-v /etc/httpd \
-v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
-v /var/lib/harbor/foreman/pod:/var/pod:rw \
-v /var/lib/harbor/foreman/ssh:/usr/share/foreman-proxy/.ssh/:rw \
-v /var/lib/harbor/foreman/dynflow:/var/lib/foreman-proxy/dynflow/:rw \
port/foreman-master:latest /sbin/init
docker logs -f foreman-master


for BRIDGE_DEVICE in br0 br1 br2; do
  # do something
  BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
  IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2"."$3".10"}')
  docker run -d -t \
  --name foreman-proxy-${BRIDGE_DEVICE} \
  --hostname foreman-proxy-${BRIDGE_DEVICE}.port.direct \
  --privileged \
  -v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
  -v /var/lib/harbor/foreman/pod:/var/pod:rw \
  -v /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}/tftpboot:/var/lib/tftpboot:rw \
  -v /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}/puppet:/var/lib/puppet/ssl:rw \
  port/foreman-proxy:latest /sbin/init
  sudo pipework ${BRIDGE_DEVICE} -i ${BRIDGE_DEVICE} -l dhcp_${BRIDGE_DEVICE} foreman-proxy-${BRIDGE_DEVICE} ${IP}/16
  docker logs -f foreman-proxy-${BRIDGE_DEVICE}
done



for BRIDGE_DEVICE in br0 br1 br2; do
  # do something
  BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
  IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2"."$3".9"}')
  sudo pipework ${BRIDGE_DEVICE} -i ${BRIDGE_DEVICE} -l foreman_${BRIDGE_DEVICE} foreman-master ${IP}/16
done
sudo touch /var/lib/harbor/foreman/pod/network-ready

for BRIDGE_DEVICE in br0 br1 br2; do
  # do something
  BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
  IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2"."$3".10"}')
  docker run -d -t \
  --name foreman-proxy-${BRIDGE_DEVICE} \
  --hostname foreman-proxy-${BRIDGE_DEVICE}.port.direct \
  --privileged \
  -v /etc/openstack/openstack.env:/etc/os-config/openstack.env:ro \
  -v /var/lib/harbor/foreman/puppet/ssl:/var/lib/puppet/ssl:rw \
  -v /var/lib/harbor/foreman/pod:/var/lib/pod:rw \
  port/foreman-proxy:latest /sbin/init
  sudo pipework ${BRIDGE_DEVICE} -i ${BRIDGE_DEVICE} -l dhcp_${BRIDGE_DEVICE} foreman-proxy-${BRIDGE_DEVICE} ${IP}/16
  sleep 5s
done
