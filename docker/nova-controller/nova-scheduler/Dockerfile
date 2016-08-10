FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT scheduler

RUN yum -y install \
        openstack-nova-scheduler && \
    yum clean all

ADD ./start.sh /start.sh
