FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

RUN apk update && \
    apk add \
        openvswitch \
        py-pip \
        supervisor && \
    rm -Rf var/cache/apk/* && \
    pip install --upgrade pip && \
    OVS_VERSION=$(ovsdb-server --version | head -1 | awk '{print $NF}') && \
    pip install ovs==${OVS_VERSION} && \
    pip install supervisor-stdout && \
    mkdir -p /var/log/supervisor

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    chmod +x /bin/*

CMD ["/usr/bin/supervisord"]
