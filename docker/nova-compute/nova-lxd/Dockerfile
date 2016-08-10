FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%

ADD ./assets/etc/yum.repos.d/elrepo-kernel.repo /etc/yum.repos.d/elrepo-kernel.repo
RUN yum install -y \
        kernel-ml-headers && \
    yum update -y && \
    yum groupinstall -y \
        "Development tools" && \
    yum install -y \
        libcap-devel \
        libcgroup \
        busybox \
        wget \
        bridge-utils && \
    yum clean all && \
    echo "# Install LXC" && \
        git clone --depth 1 -b stable-2.0 https://github.com/lxc/lxc.git  /opt/lxc && \
        cd /opt/lxc && \
            ./autogen.sh && \
            ./configure && \
            make && \
            make install && \
        ln -s /usr/local/lib/liblxc.so.1.2.0 /lib64/liblxc.so.1 && \
    echo "## Install LXD" && \
        yum install -y \
            golang \
            mercurial \
            git \
            pkgconfig \
            protobuf-compiler \
            golang-googlecode-goprotobuf-devel \
            xz \
            tar \
            acl \
            make \
            curl \
            gettext \
            jq \
            sqlite3 \
            uuid-runtime \
            pyflakes \
            pep8 \
            shellcheck \
            bzr && \
        yum clean all && \
        export GOPATH=/opt/lxd && \
        mkdir -p /opt/lxd && \
        cd $GOPATH && \
            go get github.com/lxc/lxd && \
        cd $GOPATH/src/github.com/lxc/lxd && \
            export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig && \
            make && \
        rm -f /opt/lxd/bin/deps && \
        mv /opt/lxd/bin/* /usr/bin/ && \
        mkdir -p /run/lxd-bridge/ /var/lib/lxd-bridge/ && \
        touch /etc/default/lxd-bridge && \
    echo "# Install CRIU" && \
        git clone --depth 1 https://github.com/xemul/criu /opt/criu && \
        yum install -y \
            protobuf \
            protobuf-c \
            protobuf-c-devel \
            protobuf-compiler \
            protobuf-devel \
            protobuf-python \
            libnl3 \
            libnl3-devel \
            python-ipaddr && \
        yum clean all && \
        cd /opt/criu && \
            make && \
        yum install -y \
            asciidoc \
            xmlto && \
        yum clean all && \
        cd /opt/criu && \
          make install

CMD ["/start.sh"]

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
