FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%undercloud-base:%%DOCKER_TAG%%

ENV OS_COMP="rabbitmq" \
    RABBITMQ_VERSION=3.6.1

ADD ./assets /opt/harbor/assets

# Setup Erlang, download RabbitMQ and setup the management plugin
RUN apk add --no-cache --virtual run-deps \
        erlang \
        erlang-mnesia \
        erlang-public-key \
        erlang-crypto \
        erlang-ssl \
        erlang-sasl \
        erlang-asn1 \
        erlang-inets \
        erlang-os-mon \
        erlang-xmerl \
        erlang-eldap \
        erlang-syntax-tools && \
    apk add --no-cache --virtual build-deps \
        curl \
        tar \
        xz && \
    curl -sSL https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz | tar -xJ -C / --strip-components 1 && \
    rm -rf /share/**/rabbitmq*.xz && \
    apk del build-deps && \
    addgroup rabbitmq && \
    adduser -DS -g "" -G rabbitmq -s /bin/sh -h /var/lib/rabbitmq rabbitmq && \
    mkdir -p /data/rabbitmq && \
    chown -R rabbitmq:rabbitmq /data/rabbitmq



RUN cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets
