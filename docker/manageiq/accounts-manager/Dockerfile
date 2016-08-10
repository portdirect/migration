FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%accounts-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT manager

RUN dnf install -y \
        docker-engine \
        kubernetes-client \
        etcd && \
    dnf clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
