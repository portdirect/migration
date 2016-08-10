FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT conductor

RUN yum -y install \
        openstack-nova-conductor && \
    yum clean all

ADD ./start.sh /start.sh
