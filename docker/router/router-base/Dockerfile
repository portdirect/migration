FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN yum install -y \
        dnsmasq \
        wget \
        iptables \
        nload && \
    yum clean all

ADD https://raw.github.com/jpetazzo/pipework/master/pipework /pipework
RUN chmod +x /pipework

ADD start.sh /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["/start.sh"]
