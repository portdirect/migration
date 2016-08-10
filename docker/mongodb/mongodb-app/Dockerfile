FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT os-mongodb

RUN yum -y install \
        mongodb \
        mongodb-server && \
    yum clean all

ADD start.sh /start.sh
