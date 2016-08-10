FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%designate-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="False"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
