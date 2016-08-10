FROM centos:latest
ENV OPENSTACK_COMPONENT="ovn" \
    OPENSTACK_SUBCOMPONENT="controllers"

ADD ./assets/etc/yum.repos.d/* /etc/yum.repos.d/
RUN yum install -y \
        openvswitch \
        openvswitch-ovn-central && \
    yum clean all
ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
