FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="ovn" \
    OPENSTACK_SUBCOMPONENT="ovs-base"

ADD ./assets/elrepo.repo /etc/yum.repos.d/elrepo-kernel.repo

ENV KERNEL_VERSION=4.4.16-1.el7.elrepo.x86_64

# Patched spec file untill fixed correctly uptream
ADD ./assets/opt/fedora.spec /opt/ovs/rhel/openvswitch-fedora.spec.in

RUN yum update -y && \
    yum install -y \
        git \
        kernel-lt \
        kernel-lt-devel \
        rpm-build \
        autoconf \
        automake \
        libtool \
        systemd-units \
        openssl \
        openssl-devel \
        python \
        python-twisted-core \
        python-zope-interface \
        python-six \
        desktop-file-utils \
        groff \
        graphviz \
        procps-ng \
        libcap-ng \
        libcap-ng-devel \
        dpdk-devel \
        selinux-policy-devel && \
    git clone --depth 1 --branch master https://github.com/openvswitch/ovs.git /opt/ovs-source && \
    mv /opt/ovs/rhel/openvswitch-fedora.spec.in /opt/ovs-source/rhel/openvswitch-fedora.spec.in && \
    cd /opt/ovs-source && \
      ./boot.sh && \
      ./configure --enable-ssl && \
      make rpm-fedora-kmod RPMBUILD_OPT='-D "kversion ${KERNEL_VERSION}"' && \
      make rpm-fedora RPMBUILD_OPT="--without check" && \
      make python/ovs/version.py && \
      mkdir -p /srv/python && \
      tar -cvf /srv/python/ovs.tar python/ && \
    cp -rf /opt/ovs-source/rpm/rpmbuild/RPMS/* /srv && \
    rm -rf /opt/ovs-source && \
    BUILD_INSTALL_TX=$(yum history list rpm-build | tail -2 | head -1 | awk '{ print $1}') && \
    yum history -y undo ${BUILD_INSTALL_TX} && \
    yum clean all

RUN yum install -y \
        createrepo && \
    yum clean all && \
    cd /srv && \
        createrepo .

RUN yum install -y \
        nginx && \
    yum clean all && \
    rm -rf /usr/share/nginx/html/* && \
    mv /srv/* /usr/share/nginx/html/

ADD ./assets/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# RUN yum install -y python-pip && \
#     pip install /srv/python/ovs.tar && \
#     yum install -y /srv/x86_64/*.rpm /srv/noarch/*.rpm && \
#     yum clean all && \
#     mkdir -p /var/run/openvswitch
