FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%murano-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="False"

RUN git clone --depth 1 git://github.com/HarborOS/murano.git /opt/murano-harbor

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    yum install -y \
        docker && \
    yum clean all
