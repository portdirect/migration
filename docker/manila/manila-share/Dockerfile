FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%manila-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="share"

RUN yum install -y \
        openvswitch \
    yum clean all

ADD ./start.sh /start.sh
