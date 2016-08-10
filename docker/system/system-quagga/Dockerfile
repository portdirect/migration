FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%

RUN yum install -y \
      quagga

/sbin/ip route flush proto zebra
/usr/sbin/zebra -A 127.0.0.1 -f /etc/quagga/zebra.conf
