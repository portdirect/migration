FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-sniproxy" \
    OPENSTACK_SUBCOMPONENT="base"

RUN yum install -y \
        gcc \
        autoconf \
        automake \
        curl \
        gettext-devel \
        libev-devel \
        pcre-devel \
        perl \
        pkgconfig \
        rpm-build \
        udns-devel \
        git && \
    yum clean all && \
    mkdir -p /opt/sniproxy && \
    git clone --depth 1 https://github.com/HarborOS/sniproxy /opt/sniproxy && \
    cd /opt/sniproxy && \
        ./autogen.sh && \
        ./configure && \
        make dist && \
        rpmbuild --define "_sourcedir $(pwd)" -ba redhat/sniproxy.spec && \
    yum install -y /root/rpmbuild/RPMS/x86_64/sniproxy-0.4.0-1.el7.centos.x86_64.rpm && \
    yum clean all

ADD ./start.sh /start.sh
