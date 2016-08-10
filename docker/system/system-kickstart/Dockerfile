FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN apk update && \
    apk add \
        nginx && \
    rm -Rf var/cache/apk/*

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    rm -rf /opt/harbor/assets/container && \
    chmod +x /init

CMD ["/init"]
