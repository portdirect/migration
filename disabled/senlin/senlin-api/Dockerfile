FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%senlin-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

ADD ./start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/init"]