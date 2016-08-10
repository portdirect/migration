FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

RUN apk update && \
    apk upgrade && \
    apk add --update \
        ca-certificates \
        docker \
        openssl \
        tar \
        sipcalc \
        openssh-client && \
    wget https://github.com/coreos/etcd/releases/download/v2.0.10/etcd-v2.0.10-linux-amd64.tar.gz && \
    tar xzvf etcd-v2.0.10-linux-amd64.tar.gz && \
    mv etcd-v2.0.10-linux-amd64/etcdctl /bin/ && \
    apk del --purge \
        tar \
        openssl \
        ca-certificates && \
    rm -Rf etcd-v2.0.10-linux-amd64* && \
    rm -Rf var/cache/apk/*


ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    rm -rf /opt/harbor/assets/container && \
    chmod +x /init /bin/*

CMD ["/init"]
