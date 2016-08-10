FROM centos:latest
ENV OPENSTACK_COMPONENT="ovs" \
    OPENSTACK_SUBCOMPONENT="node"

ADD ./assets/etc/yum.repos.d/* /etc/yum.repos.d/
RUN yum install -y \
        openvswitch \
        openvswitch-ovn-host && \
    yum clean all
ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
