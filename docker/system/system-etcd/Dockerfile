FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

RUN apk add --update \
        ca-certificates \
        openssl \
        tar && \
    wget https://github.com/coreos/etcd/releases/download/v2.0.10/etcd-v2.0.10-linux-amd64.tar.gz && \
    tar xzvf etcd-v2.0.10-linux-amd64.tar.gz && \
    mv etcd-v2.0.10-linux-amd64/etcd /bin/ && \
    apk del --purge \
        tar \
        ca-certificates \
        openssl && \
    rm -Rf etcd-v2.0.10-linux-amd64* && \
    rm /var/cache/apk/*

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    chmod +x /bin/* && \
    chmod +x /opt/harbor/assets/host/bin/*

VOLUME ["/data"]
