FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%designate-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OPENSTACK_SUBCOMPONENT api
ENV INIT_DB_REQUIRED True
ENV INIT_KEYSTONE_REQUIRED True
ENV IPA_BACKED True

RUN yum install -y \
        openstack-designate-api && \
    yum clean all
