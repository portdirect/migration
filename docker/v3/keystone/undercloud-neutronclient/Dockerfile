FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%undercloud-base:%%DOCKER_TAG%%

ENV OS_COMP="neutronclient"

ADD ./assets /opt/harbor/assets

RUN apk add --no-cache --virtual build-deps \
        gcc \
        musl-dev \
        python-dev \
        linux-headers \
        openssl-dev && \
    mkdir -p /opt/stack && \
    pip install pbr && \
    pip install python-neutronclient && \
    apk del build-deps && \
    mkdir -p /var/log/${OS_COMP} && \
    addgroup ${OS_COMP} -g 1000 && \
    adduser -u 1000 -D -s /bin/false -G ${OS_COMP} ${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/log/${OS_COMP} && \
    cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets
