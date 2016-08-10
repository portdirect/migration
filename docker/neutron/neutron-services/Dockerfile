FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%neutron-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT services


RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
    easy_install supervisor && \
    yum install -y \
        python-pip && \
    yum clean all && \
    pip install --upgrade pip && \
    pip install supervisor-stdout && \
    yum install -y \
        openstack-neutron \
        openstack-neutron-openvswitch \
        net-tools \
        ebtables \
        python-barbicanclient \
        openstack-neutron-lbaas \
        haproxy \
        http://dl.fedoraproject.org/pub/fedora/linux/releases/21/Everything/x86_64/os/Packages/d/dnsmasq-2.72-3.fc21.x86_64.rpm && \
    yum clean all && \
    mkdir -p /var/log/supervisor

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
