FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%
ENV MODULE discs

RUN apk update && \
    apk add \
        util-linux \
        parted \
        lvm2 \
        xfsprogs && \
    rm -Rf /var/cache/apk/*

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    chmod +x /bin/* && \
    chmod +x /opt/harbor/assets/host/bin/*

VOLUME ["/data"]
