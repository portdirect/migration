FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%accounts-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT portal

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
