FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="compute" \
    IPA_BACKED="False"

RUN yum -y install \
        centos-release-gluster37 && \
    yum -y install \
        glusterfs \
        glusterfs-fuse \
        kernel-ml \
        openstack-nova-compute \
        openvswitch \
        ethtool \
        sysfsutils && \
    yum clean all && \
    mkdir -p /var/lib/nova/instances && \
    ln -s /lib/udev/scsi_id /usr/bin/scsi_id && \
    echo "Installing supervisord so we can run both the hyperisor and nova-compute in the same mount namespace" && \
    easy_install supervisor && \
    yum install -y \
        python-pip && \
    yum clean all && \
    pip install --upgrade pip && \
    pip install supervisor-stdout
