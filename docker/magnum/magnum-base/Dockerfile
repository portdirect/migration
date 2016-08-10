FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-magnum" \
    INIT_DB_REQUIRED="True" \
    OPENSTACK_SUBCOMPONENT="base"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
    yum install -y \
        openstack-magnum-api \
        openstack-magnum-common \
        openstack-magnum-conductor \
        python-magnumclient \
	  yum clean all

RUN yum install -y \
        python-pip && \
    pip install --upgrade pip && \
    pip install --upgrade oslo.config && \
    pip install --upgrade oslo.log && \
    pip install --upgrade python-barbicanclient

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
