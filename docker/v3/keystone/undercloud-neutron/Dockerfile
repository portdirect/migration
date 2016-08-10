FROM centos:latest

ENV OS_COMP="neutron" \
    OS_REPO_URL="https://github.com/openstack/neutron.git" \
    OS_REPO_BRANCH="master" \
    OS_COMP_1="networking-ovn" \
    OS_REPO_URL_1="https://github.com/openstack/networking-ovn.git" \
    OS_REPO_BRANCH_1="master" \
    OS_COMP_2="neutron-lbass" \
    OS_REPO_URL_2="https://github.com/openstack/neutron-lbaas.git" \
    OS_REPO_BRANCH_2="master"

ADD ./assets/etc/yum.repos.d/* /etc/yum.repos.d/
RUN yum install -y \
        epel-release \
        centos-release-gluster37 \
        centos-release-openstack-mitaka && \
    yum update -y && \
    yum install -y \
        openvswitch \
        python-openvswitch \
        iproute \
        net-tools \
        ethtool \
        findutils \
        iptables \
        openssh-clients \
        python \
        python-pip \
        mariadb \
        mariadb-libs \
        sudo \
    yum install -y \
        haproxy && \
    yum install -y \
        gcc \
        git \
        kernel-lt \
        kernel-lt-headers \
        python-devel \
        python-devel \
        libffi-devel \
        postgresql-devel \
        openssl-devel && \
    yum clean all

ENV OS_COMP="neutron" \
    OS_REPO_URL="https://github.com/openstack/neutron.git" \
    OS_REPO_BRANCH="master" \
    OS_REPO_COMMIT="f7ec19ad0138a44d5e9d0e539aa7f8066d3d09b0" \
    OS_COMP_1="networking-ovn" \
    OS_REPO_URL_1="https://github.com/openstack/networking-ovn.git" \
    OS_REPO_BRANCH_1="master" \
    OS_COMP_2="neutron-lbass" \
    OS_REPO_URL_2="https://github.com/openstack/neutron-lbaas.git" \
    OS_REPO_BRANCH_2="master"


RUN mkdir -p /opt/stack && \
    pip --no-cache-dir install --upgrade pip setuptools && \
    pip --no-cache-dir install crudini && \
    pip --no-cache-dir install PyMySQL && \
    pip --no-cache-dir install python-memcached && \
    git clone ${OS_REPO_URL} /opt/stack/${OS_COMP} && \
    cd /opt/stack/${OS_COMP} && \
      git checkout ${OS_REPO_COMMIT} && \
      cd / && \
    git clone ${OS_REPO_URL_1} -b ${OS_REPO_BRANCH_1} --depth 1 /opt/stack/${OS_COMP_1} && \
    cd /opt/stack/${OS_COMP_1}  && \
         git fetch git://git.openstack.org/openstack/networking-ovn refs/changes/05/315305/18 && \
         git checkout FETCH_HEAD && \
         cd / && \
    git clone ${OS_REPO_URL_2} -b ${OS_REPO_BRANCH_2} --depth 1 /opt/stack/${OS_COMP_2} && \
    pip --no-cache-dir install /opt/stack/${OS_COMP} && \
    pip --no-cache-dir install /opt/stack/${OS_COMP_1} && \
    pip --no-cache-dir install /opt/stack/${OS_COMP_2} && \
    mkdir -p /var/log/${OS_COMP} && \
    mkdir -p /var/lib/${OS_COMP}/lock && \
    mkdir -p /var/lib/${OS_COMP}/state && \
    mkdir -p /var/lib/${OS_COMP}/state/lbaas && \
    mkdir -p /etc/${OS_COMP} && \
    mkdir -p /var/cache/${OS_COMP} && \
    cp /opt/stack/neutron/etc/*.ini /etc/${OS_COMP}/ && \
    cp /opt/stack/neutron/etc/*.conf /etc/${OS_COMP}/ && \
    cp /opt/stack/neutron/etc/*.json /etc/${OS_COMP}/ && \
    groupadd ${OS_COMP} -g 1000 && \
    adduser -u 1000 -g ${OS_COMP} --system  ${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/log/${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/lib/${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/cache/${OS_COMP} && \
    rm -rf /opt/stack && \
    yum clean all


ADD ./assets /opt/harbor/assets

RUN cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    chmod 0440 /etc/sudoers
