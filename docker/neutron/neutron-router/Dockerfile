FROM centos:7
LABEL License="Apache 2.0" \
      Vendor="Harbor OpenStack"
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV container=docker \
    OS_DISTRO="HarborOS"

CMD ["/init"]

RUN yum install -y \
        epel-release \
        centos-release-openstack-mitaka && \
    yum update -y && \
    yum install -y \
        iptables \
        iproute \
        curl \
        bridge-utils \
        openvswitch && \
    yum clean all && \
    curl -L https://raw.github.com/jpetazzo/pipework/master/pipework > /bin/pipework && \
    chmod +x /bin/pipework

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
