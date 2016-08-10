FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN yum install -y \
        git \
        make && \
    yum clean all

RUN git clone https://github.com/projectcalico/calico-cni.git /opt/calico-cni
RUN cd /opt/calico-cni; git pull origin pull/113/head
RUN cd /opt/calico-cni; make
