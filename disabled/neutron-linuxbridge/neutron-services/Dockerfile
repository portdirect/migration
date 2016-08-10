FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%neutron-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT services

RUN curl https://trunk.rdoproject.org/centos7-liberty/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-liberty/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    easy_install supervisor && \
    yum install -y \
        python-pip && \
    yum clean all && \
    pip install --upgrade pip && \
    pip install supervisor-stdout && \
    yum install -y \
        openstack-neutron \
        openstack-neutron-linuxbridge \
        net-tools \
        ebtables \
        python-barbicanclient \
        openstack-neutron-lbaas \
        haproxy && \
    yum clean all && \
    mkdir -p /var/log/supervisor

# This is needed to workaround a problem with the agents exiting if the
# file is not present.  This file really shouldn't need to be present and
# implies a configuration problem somewhere else in the code base, but
# we are out of time.
COPY fwaas_driver.ini /etc/neutron/

# Configure supervisord
ADD supervisord.conf /etc/

# Add config scripts
ADD config-scripts/ /opt/harbor/neutron/
RUN mv /opt/harbor/neutron/config-sudoers.sh /opt/harbor/ && \
    chmod +x /opt/harbor/neutron/*.sh

# Add check scripts
ADD check-scripts/ /opt/harbor/neutron/

ADD ./start.sh /start.sh
