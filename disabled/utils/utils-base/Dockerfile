FROM alpine:latest
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN apk update && \
    apk add util-linux sipcalc bash && \
    apk add --update ca-certificates openssl tar && \
    wget https://github.com/coreos/etcd/releases/download/v2.0.10/etcd-v2.0.10-linux-amd64.tar.gz && \
    tar xzvf etcd-v2.0.10-linux-amd64.tar.gz && \
    mv etcd-v2.0.10-linux-amd64/etcd* /bin/ && \
    apk del --purge tar openssl && \
    rm -Rf etcd-v2.0.10-linux-amd64* /var/cache/apk/* /bin/etcd
