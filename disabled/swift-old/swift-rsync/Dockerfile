FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%swift-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="rsync"

RUN yum -y install \
        rsync && \
    yum clean all

COPY ./start.sh /start.sh
