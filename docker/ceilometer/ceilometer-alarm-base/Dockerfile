FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ceilometer-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="alarm"

RUN yum install -y \
        openstack-ceilometer-alarm && \
    yum clean all
