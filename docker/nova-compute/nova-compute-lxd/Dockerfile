FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-compute-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="compute" \
    IPA_BACKED="False"

RUN yum -y install \
        openstack-nova-compute \
        spice-html5 \
        sysfsutils \
        kernel-ml-headers \
        go \
        lxc-devel \
        git && \
    yum clean all && \
    pip install --upgrade six && \
    pip install pylxd && \
    pip install nova-lxd && \
    export WORK_DIR="/opt/lxd" && \
    export GOPATH="/opt/lxd/go" && \
    mkdir -p $GOPATH && \
    cd $WORK_DIR && \
    go get -v -u github.com/lxc/lxd && \
    cd $GOPATH/src/github.com/lxc/lxd && \
    make && \
    cp /opt/lxd/go/bin/* /usr/bin/

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
