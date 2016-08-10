FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-designate" \
    INIT_DB_REQUIRED="True" \
    OPENSTACK_SUBCOMPONENT="base"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum install -y \
        openstack-designate-agent \
        openstack-designate-api \
        openstack-designate-central \
        openstack-designate-common \
        openstack-designate-mdns \
        openstack-designate-pool-manager \
        openstack-designate-sink \
        openstack-designate-zone-manager  \
        python-designateclient \
        python2-oslo-reports \
        python-suds \
        python-tooz \
        bind-utils && \
    yum clean all && \
    mkdir -p /var/log/designate && \
    chown -R designate /var/log/designate

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / 
