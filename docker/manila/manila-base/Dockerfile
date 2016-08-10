FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-manila" \
    INIT_DB_REQUIRED="True" \
    OPENSTACK_SUBCOMPONENT="base"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
    yum install -y \
        openstack-manila \
        openstack-manila-share \
        python-manilaclient \
    yum clean all && \
    mkdir -p /var/log/manila && \
    chown -R manila /var/log/manila

RUN mkdir -p /var/lib/os-manila && \
    chown -R manila /var/lib/os-manila && \
    mkdir -p /var/lock/manila && \
    chown -R manila /var/lock/manila && \
    mkdir -p /home/manila/.ssh

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
