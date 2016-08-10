FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%utils-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN apk update && \
    apk add \
        bridge-utils \
        sipcalc \
        bash \
        docker && \
    rm /var/cache/apk/*

ADD ./register.sh /bin/register
ADD ./prep-docker.sh /bin/prep-docker
ADD ./update-ovs.sh /bin/update-ovs
ADD ./etcd-monitor.sh /bin/etcd-monitor
RUN chmod +x /bin/register /bin/prep-docker /bin/update-ovs /bin/etcd-monitor
