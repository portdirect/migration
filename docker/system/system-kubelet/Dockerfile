FROM centos:latest

ENV KURYR_REPO="https://github.com/midonet/kuryr.git" \
    KURYR_BRANCH="k8s" \
    KUBE_LATEST_VERSION="v1.3.0"

# 9c66675c22ea9192a5845461cafd26414d49143b

ADD ./assets/etc/yum.repos.d/* /etc/yum.repos.d/
RUN yum install -y \
        epel-release \
        centos-release-gluster37 \
        centos-release-openstack-mitaka && \
    yum update -y && \
    yum install -y \
        openvswitch \
        python34 \
        python34-devel \
        sudo \
        ethtool \
        mariadb \
        jq \
        docker-engine && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    chmod 0440 /etc/sudoers && \
    curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubelet > /usr/bin/kubelet && \
    chmod +x /usr/bin/kubelet && \
    curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl > /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl && \
    yum install -y \
      git \
      gcc && \
    curl -s https://bootstrap.pypa.io/get-pip.py | python3 && \
    git clone --depth 1 ${KURYR_REPO} -b ${KURYR_BRANCH} /opt/kuryr  && \
    pip3 install /opt/kuryr && \
    BUILD_INSTALL_TX=$(yum history list gcc | tail -2 | head -1 | awk '{ print $1}') && \
    yum history -y undo ${BUILD_INSTALL_TX} && \
    yum clean all

# What a horrible hack. Whats going on here?
RUN /bin/cp -f /opt/kuryr/usr/libexec/kuryr/ovs /opt/kuryr/usr/libexec/kuryr/unbound

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/* / && \
    mkdir -p /etc/kubernetes/manifests


CMD ["/kubelet"]
