FROM centos:7
LABEL License="Apache 2.0" \
      Vendor="Harbor OpenStack"
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV container=docker \
    OS_DISTRO="HarborOS"

RUN yum update -y && \
    yum install -y \
        iptables \
        iproute \
        curl \
        bridge-utils && \
    yum clean all && \
    curl -L https://raw.github.com/jpetazzo/pipework/master/pipework > /bin/pipework && \
    chmod +x /bin/pipework

ADD ./start.sh /start.sh
ADD ./init /init
RUN chmod +x /init
CMD ["/init"]
