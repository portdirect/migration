FROM docker.io/alpine:latest
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS
ENV OPENSTACK_COMPONENT os-haproxy
ENV OPENSTACK_SUBCOMPONENT base

RUN apk update && \
    apk upgrade && \
    apk add --update \
        haproxy && \
    rm -Rf var/cache/apk/*
