FROM docker.io/alpine:latest
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

RUN apk update && \
    apk upgrade && \
    apk add --update \
        ca-certificates \
        openssl \
        tar && \
    wget https://github.com/coreos/etcd/releases/download/v2.0.10/etcd-v2.0.10-linux-amd64.tar.gz && \
    tar xzvf etcd-v2.0.10-linux-amd64.tar.gz && \
    mv etcd-v2.0.10-linux-amd64/etcdctl /bin/ && \
    apk del --purge \
        tar \
        openssl \
        ca-certificates && \
    rm -Rf etcd-v2.0.10-linux-amd64* && \
    rm -Rf /var/cache/apk/*
