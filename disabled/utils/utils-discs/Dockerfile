FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%utils-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN apk update && \
    apk add \
      parted \
      lvm2 \
      xfsprogs && \
    rm -Rf /var/cache/apk/*

ADD ./assets/ /opt/harbor/
RUN chmod +x /opt/harbor/*

ADD ./init /init
RUN chmod +x /init
CMD ["/init"]
