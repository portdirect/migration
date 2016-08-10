FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ceilometer-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="collector"

RUN yum install -y \
        openstack-ceilometer-collector && \
    yum clean all

ADD ./start.sh /start.sh
