FROM ubuntu:16.04
ENV OS_DISTRO="HarborOS" \
    IPA_BACKED="False" \
    SECURE_CONFIG="True" \
    container=docker \
    OPENSTACK_COMPONENT="nova" \
    OPENSTACK_SUBCOMPONENT="lxd" \
    INIT_DB_REQUIRED="True" \
    DEBIAN_FRONTEND="noninteractive"

LABEL license="Apache 2.0" \
      vendor="Harbor OpenStack"

RUN apt-get update && \
    apt-get install -y \
            lxd \
            criu \
            iproute2 \
            crudini \
            curl \
            etcd \
            bridge-utils \
            dnsutils && \
    apt-get clean

CMD ["/start.sh"]

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
