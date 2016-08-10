FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%keystone-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT keystone-v2-default

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
