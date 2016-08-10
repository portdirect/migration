FROM gcr.io/google_containers/hyperkube:v1.3.0
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    chmod +x /bin/* && \
    KUBE_LATEST_VERSION="v1.3.0" && \
    mkdir -p /usr/bin && \
    curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl > /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl && \
    mkdir -p /opt/harbor/assets/host/bin && \
    mv /usr/bin/kubectl /opt/harbor/assets/host/bin/kubectl && \
    apt-get update && \
    apt-get -y install \
        git \
        python3 \
        python3-dev \
        build-essential --no-install-recommends && \
    curl -s https://bootstrap.pypa.io/get-pip.py | python3 &&  \
    git clone --depth 1 http://github.com/midonet/kuryr /opt/kuryr -b k8s && \
    sed -i "s/FALLBACK_VIF_TYPE = 'unbound'/FALLBACK_VIF_TYPE = 'ovs'/g" /opt/kuryr/kuryr/binding.py && \
    cd /opt/kuryr && \
    pip3 install . && \
    apt-get install -y \
        openvswitch-switch \
        python-openvswitch \
        sudo && \
    rm -fr /var/lib/apt/lists/*

# # Install Java 8 (jessie-backports must be added)
RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
    && apt-get -qqy update \
    && apt-get install -qy openjdk-8-jdk --no-install-recommends \
    && rm -fr /var/lib/apt/lists/*

# Midonet key
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv \
     E9996503AEB005066261D3F38DDA494E99143E75

# Install mm-ctl
RUN apt-get -y update \
    && apt-get install -qqy python-setproctitle \
    && cd /tmp \
    && apt-get download midolman \
    && mv midolman* midolman.deb \
    && dpkg -i --ignore-depends=openvswitch-datapath-dkms,bridge-utils,haproxy,quagga,libreswan,iproute,midonet-tools /tmp/midolman.deb \
    && rm -fr /var/lib/apt/lists/* /etc/apt/sources.list.d/*

# Set ENV VARS
ENV MASTER_IP="127.0.0.1"
ENV ZK_ENDPOINTS="127.0.0.1:2181"
ENV UUID=""


CMD ["/kubelet"]
#RUN mv /opt/kuryr/usr/libexec/kuryr/ovs /opt/kuryr/usr/libexec/kuryr/unbound
