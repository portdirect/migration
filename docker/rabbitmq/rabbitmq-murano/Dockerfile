FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%rabbitmq-base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-messaging"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
