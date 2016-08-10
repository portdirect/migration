FROM centos:7
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN yum update -y && \
    yum upgrade -y && \
    yum install -y \
        qemu-img && \
    yum clean all
