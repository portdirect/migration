FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-cinder" \
    OPENSTACK_SUBCOMPONENT="base" \
    INIT_DB_REQUIRED="True"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
    yum -y install \
        openstack-cinder \
        python-cinderclient \
        python-barbicanclient \
        python-automaton \
        lvm2 \
        glusterfs \
        glusterfs-fuse \
        python-oslo-policy \
        python-keystonemiddleware && \
    yum clean all && \
    sed -i "s|udev_rules = 1|udev_rules = 0|g" /etc/lvm/lvm.conf &&  \
    sed -i "s|udev_sync = 1|udev_sync = 0|g" /etc/lvm/lvm.conf

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
