FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OPENSTACK_COMPONENT os-designate

# Install designate-api because of /etc/designate/policy.json, which
# is needed in all services. This is probably a packaging bug. We do
# need the complete policy file because of some of the containers'
# requiring it. Remove the package when the file is moved though.
RUN yum install -y \
        openstack-designate-api && \
    cp /etc/designate/policy.json /tmp/ && \
    yum remove -y \
        openstack-designate-api && \
    yum install -y \
        openstack-designate-common \
        python-tooz && \
    yum clean all && \
    mv /tmp/policy.json /etc/designate/

COPY config-designate.sh /opt/harbor/config-designate.sh
