FROM ubuntu:16.04
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV OS_DISTRO="HarborOS" \
    OPENSTACK_COMPONENT="ubuntu-guest" \
    LC_ALL="en_US.UTF-8" \
    container=docker \
    DEBIAN_FRONTEND="noninteractive"

LABEL license="Apache 2.0" \
      vendor="Harbor OpenStack"

RUN locale-gen en_US.UTF-8 && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
        systemd \
        iproute \
        curl \
        iputils-ping \
        cloud-init \
        openssh-client \
        openssh-server \
        nfs-common \
        heat-cfntools \
        sudo \
        crudini \
        net-tools && \
    apt-get clean && \
    useradd ubuntu && \
    /bin/bash -c 'cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [[ $i == systemd-tmpfiles-setup.service ]] || rm -f $i; done'; \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;


VOLUME [ "/sys/fs/cgroup" , "/run", "/tmp" ]
CMD [ "/sbin/init" ]

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    systemctl enable cloud-init && \
    sed -i 's/exit 101/exit 0/' /usr/sbin/policy-rc.d
