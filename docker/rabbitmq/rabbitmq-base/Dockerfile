FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-messaging"

RUN yum -y install \
        rabbitmq-server && \
    yum clean all && \
    /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management
