FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-trove" \
    INIT_DB_REQUIRED="True" \
    OPENSTACK_SUBCOMPONENT="base"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum install -y \
        openstack-trove-api \
        openstack-trove-common \
        openstack-trove-conductor \
        openstack-trove-taskmanager \
        python-troveclient \
        python-oslo-db && \
    yum clean all && \
    mkdir -p /var/log/trove && \
    chown -R trove /var/log/trove


ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
