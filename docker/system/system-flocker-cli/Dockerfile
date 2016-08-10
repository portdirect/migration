FROM docker.io/centos:latest
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

RUN yum install -y epel-release && \
    yum install -y update || true && \
    yum install -y upgrade || true && \
    yum install -y docker sudo && \
    curl -L https://get.flocker.io > /opt/flocker-install.sh && \
    chmod +x /opt/flocker-install.sh

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/* /
