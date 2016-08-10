FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%utils-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

ADD ./assets/ /opt/install

ADD ./init.sh /init

CMD ["/init"]
