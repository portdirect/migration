FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%host-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV DOCKER_NAMESPACE %%DOCKER_NAMESPACE%%
#ENV DOCKER_PREFIX %%DOCKER_PREFIX%%
ENV DOCKER_TAG %%DOCKER_TAG%%

ADD ./host.sh /assets/host.sh

RUN sed -i "s/{{DOCKER_NAMESPACE}}/${DOCKER_NAMESPACE}/" /assets/host.sh && \
    sed -i "s/{{DOCKER_TAG}}/${DOCKER_TAG}/" /assets/host.sh && \
    chmod +x /assets/host.sh

# This container requires manual completion of the build.
# after building run the following commands on the host.
# DOCKER_ID=$(docker run -d -v /tmp/host-build:/assets docker.io/port/host-base:latest tail -f /dev/null)
# DOCKER_ID=$(docker run -d -v /assets docker.io/port/host-images:latest tail -f /dev/null)
# get the mount location
# DOCKER_MNT=$(docker inspect -f '{{ .Mounts }}' $DOCKER_ID | awk '{ print $2}')
# cd ${DOCKER_MNT} && ./host.sh
