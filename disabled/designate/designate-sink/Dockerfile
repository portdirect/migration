FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%designate-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OPENSTACK_SUBCOMPONENT sink
ENV INIT_DB_REQUIRED True

RUN yum install -y \
        openstack-designate-sink \
        python-designateclient && \
    yum clean all
