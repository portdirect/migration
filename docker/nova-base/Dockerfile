FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-nova" \
    INIT_DB_REQUIRED="True"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
    yum -y install \
        openstack-nova-common \
        python-keystoneclient \
        python-cinderclient \
        python-nova \
        bridge-utils \
        python-docker && \
    yum clean all

ADD ./assets /opt/harbor/assets

RUN  yum install -y \
          git \
          python-pip && \
    pip install --upgrade pip && \
    pip install --upgrade setuptools && \
    git clone --depth 1 https://github.com/openstack/nova-docker.git /opt/docker-nova && \
    /bin/cp -rf /opt/harbor/assets/* / && \
    cd /opt/docker-nova && \
        pip install -r requirements.txt && \
        python setup.py install && \
    yum autoremove -y \
        git && \
    yum clean all && \
    echo "Patching Libvirt Driver: https://bugs.launchpad.net/ubuntu/+source/nova/+bug/1567807" && \
    rm -f /usr/lib/python2.7/site-packages/nova/virt/libvirt/guest.pyo && \
    rm -f /usr/lib/python2.7/site-packages/nova/virt/libvirt/guest.pyc && \
    sed -i 's/libvirt.VIR_DOMAIN_UNDEFINE_MANAGED_SAVE/libvirt.VIR_DOMAIN_UNDEFINE_MANAGED_SAVE | libvirt.VIR_DOMAIN_UNDEFINE_NVRAM/' /usr/lib/python2.7/site-packages/nova/virt/libvirt/guest.py && \
    echo "Patching Nova To Force DNS Sync with neutron" && \
    rm -f /usr/lib/python2.7/site-packages/nova/network/neutronv2/api.pyo && \
    rm -f /usr/lib/python2.7/site-packages/nova/network/neutronv2/api.pyc
