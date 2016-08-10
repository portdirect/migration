FROM centos:7
LABEL License="Apache 2.0" \
      Vendor="Harbor OpenStack"
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO="Harbor" \
    container="docker"

ADD ./assets/etc/yum.repos.d/nginx.repo /etc/yum.repos.d/nginx.repo

RUN curl http://nginx.org/keys/nginx_signing.key > /tmp/nginx_signing.key && \
    rpm --import /tmp/nginx_signing.key && \
    rm -f /tmp/nginx_signing.key && \
    yum install -y \
        epel-release \
        centos-release-openstack-liberty && \
    yum update -y && \
    yum install -y \
        nginx && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /

CMD ["/start.sh"]
