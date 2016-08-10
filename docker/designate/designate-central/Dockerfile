FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%designate-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="central"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
