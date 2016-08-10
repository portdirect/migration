FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%undercloud-base:%%DOCKER_TAG%%

ENV OS_COMP="openstackclient"

RUN apk add --no-cache --virtual build-deps \
        gcc \
        musl-dev \
        python-dev \
        linux-headers \
        openssl-dev && \
    mkdir -p /opt/stack && \
    pip install pbr && \
    pip install python-openstackclient && \
    apk del build-deps && \
    apk add --no-cache --virtual run-deps \
        docker && \
    mkdir -p /var/log/${OS_COMP} && \
    addgroup ${OS_COMP} -g 1000 && \
    adduser -u 1000 -D -s /bin/false -G ${OS_COMP} ${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/log/${OS_COMP}

ADD ./assets /opt/harbor/assets

RUN cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets
