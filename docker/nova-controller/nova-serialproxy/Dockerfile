FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT spicehtml5-proxy

RUN yum -y install \
        openstack-nova-serialproxy && \
    yum clean all

ADD start.sh /start.sh
