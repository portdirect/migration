FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%swift-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OPENSTACK_SUBCOMPONENT account-server

RUN yum -y install \
        openstack-swift-account \
    && yum clean all

ADD account-server.conf /etc/swift/account-server.conf
COPY start.sh /
