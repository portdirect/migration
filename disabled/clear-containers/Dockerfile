FROM centos:7
LABEL License="Apache 2.0" \
      Vendor="Harbor OpenStack"
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV OS_DISTRO HarborOS
ENV container=docker
ENV IPA_BACKED False
ENV SECURE_CONFIG True

ADD http://download.opensuse.org/repositories/home:clearlinux:preview/CentOS_7/home:clearlinux:preview.repo /etc/yum.repos.d/clearlinux:preview.repo

RUN yum install -y \
        epel-release \
        centos-release-openstack-liberty && \
    yum update -y && \
    yum install -y \
        clear-containers-docker && \
    yum clean all

ADD start.sh /init
RUN chmod +x /init

CMD ["/init"]
