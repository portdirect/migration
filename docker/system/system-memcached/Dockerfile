FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

RUN apk update && \
    apk add \
        memcached && \
    rm -Rf var/cache/apk/*

USER memcached
ENTRYPOINT ["/usr/bin/memcached"]
CMD ["-v","-l","127.0.0.1:11211"]
