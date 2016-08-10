FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%murano-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="api"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
