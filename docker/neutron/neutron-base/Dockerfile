FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-neutron" \
    INIT_DB_REQUIRED="True"

RUN yum install -y \
        openstack-neutron \
        openstack-neutron-ml2 \
        python-barbicanclient \
        python-designateclient \
        openstack-neutron-lbaas \
        openstack-neutron-fwaas \
        openstack-neutron-openvswitch \
        bridge-utils \
        tcpdump \
        bind-utils \
        openvswitch && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    chmod 0440 /etc/sudoers && \
    rm -f ./assets/usr/lib/python2.7/site-packages/neutron/agent/linux/dhcp.pyc && \
    rm -f ./assets/usr/lib/python2.7/site-packages/neutron/agent/linux/dhcp.pyo && \
    rm -f ./assets/usr/lib/python2.7/site-packages/neutron_lbaas/db/loadbalancer/loadbalancer_db.pyc && \
    rm -f ./assets/usr/lib/python2.7/site-packages/neutron_lbaas/db/loadbalancer/loadbalancer_db.pyo
