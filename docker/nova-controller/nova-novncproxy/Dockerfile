FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT novnc-proxy

RUN yum -y install \
        novnc \
        openstack-nova-novncproxy && \
    yum clean all

ADD start.sh /start.sh
