FROM docker.io/centos:latest
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

RUN yum install -y epel-release && \
    yum install -y update || true && \
    yum install -y upgrade || true && \
    yum install -y https://clusterhq-archive.s3.amazonaws.com/centos/clusterhq-release.el7.centos.noarch.rpm && \
    yum install -y clusterhq-flocker-node && \
    yum install -y clusterhq-flocker-cli && \
    yum install -y clusterhq-flocker-docker-plugin
