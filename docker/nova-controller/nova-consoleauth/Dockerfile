FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT console-auth

RUN yum -y install \
        openstack-nova-console && \
    yum clean all

ADD ./start.sh /start.sh
