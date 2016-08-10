FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="swift" \
    OPENSTACK_SUBCOMPONENT="rsync"

RUN yum -y install \
        rsync && \
    yum clean all

ADD ./start.sh /start.sh
