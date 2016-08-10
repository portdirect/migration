FROM centos:7
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO="HarborOS" \
    IPA_BACKED="False" \
    SECURE_CONFIG="True" \
    container=docker
LABEL license="Apache 2.0" \
      vendor="Harbor OpenStack"

ADD ./assets/etc/yum.repos.d /opt/repos

RUN /bin/cp -rf /opt/repos/* /etc/yum.repos.d/ && \
    rm -rf /opt/repos && \
    yum install -y \
        epel-release \
        centos-release-gluster37 \
        centos-release-openstack-mitaka && \
    yum update -y && \
    yum upgrade -y && \
    yum install -y \
        python-openstackclient \
        python-memcached \
        openstack-selinux \
        mariadb \
        MySQL-python \
        crudini \
        etcd \
        kubernetes-client && \
    yum clean all

ADD ./assets/ /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /

CMD ["/init"]
