FROM gcr.io/google_containers/hyperkube:v1.3.0
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

ENV KURYR_REPO="https://github.com/midonet/kuryr.git" \
    KURYR_BRANCH="k8s"

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/* / && \
    apt-get update && \
    apt-get -y install \
        git \
        sudo \
        python3 \
        python3-dev \
        build-essential --no-install-recommends && \
    curl -s https://bootstrap.pypa.io/get-pip.py | python3 &&  \
    git clone --depth 1 ${KURYR_REPO} -b ${KURYR_BRANCH} /opt/kuryr  && \
    pip3 install /opt/kuryr && \
    rm -fr /var/lib/apt/lists/*

# # Install Java 8 (jessie-backports must be added)
RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
    && apt-get -qqy update \
    && apt-get install -qy openjdk-8-jdk --no-install-recommends \
    && rm -fr /var/lib/apt/lists/* && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E9996503AEB005066261D3F38DDA494E99143E75 && \
    apt-get -y update \
    && apt-get install -qqy python-setproctitle \
    && cd /tmp \
    && apt-get download midolman \
    && mv midolman* midolman.deb \
    && dpkg -i --ignore-depends=openvswitch-datapath-dkms,bridge-utils,haproxy,quagga,libreswan,iproute,midonet-tools /tmp/midolman.deb \
    && rm -fr /var/lib/apt/lists/* /etc/apt/sources.list.d/*

# Set ENV VARS
ENV MASTER_IP="127.0.0.1" \
    ZK_ENDPOINTS="127.0.0.1:2181" \
    UUID=""

CMD ["/kubelet"]
#RUN mv /opt/kuryr/usr/libexec/kuryr/ovs /opt/kuryr/usr/libexec/kuryr/unbound
