FROM centos:7
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV OS_DISTRO="HarborOS" \
    OPENSTACK_COMPONENT="centos-guest" \
    LC_ALL="en_US.UTF-8" \
    container=docker

LABEL license="Apache 2.0" \
      vendor="Harbor OpenStack"

RUN yum install -y \
        epel-release \
        centos-release-openstack-mitaka && \
    yum update -y && \
    yum install -y \
        iproute \
        cloud-init \
        openssh-clients \
        openssh-server \
        nfs-utils \
        heatcfn-tools \
        sudo \
        crudini \
        dhclient && \
    yum clean all && \
    useradd centos && \
    (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ "/sys/fs/cgroup" , "/run", "/tmp" ]
CMD ["/usr/sbin/init"]

ADD ./assets /opt/harbor/assets
RUN /bin/mv /usr/bin/hostnamectl /usr/bin/.hostnamectl && \
    /bin/cp -rf /opt/harbor/assets/* / && \
    systemctl enable cloud-config
