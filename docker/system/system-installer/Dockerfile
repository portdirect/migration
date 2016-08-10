FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN apk update && \
    apk upgrade && \
    rm -Rf var/cache/apk/*

ADD ./assets/ /opt
RUN mv /opt/init /init && \
    chmod +x init
