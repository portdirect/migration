FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%barbican-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="api" \
    IPA_BACKED="True"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
