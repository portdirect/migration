FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OPENSTACK_COMPONENT os-memcached
ENV OPENSTACK_SUBCOMPONENT server

RUN yum -y install \
        memcached && \
    yum clean all

ADD ./start.sh /start.sh

EXPOSE 11211/tcp
