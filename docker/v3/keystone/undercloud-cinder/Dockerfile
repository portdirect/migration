FROM centos:latest

ENV OS_COMP="cinder" \
    OS_REPO_URL="https://github.com/openstack/cinder.git" \
    OS_REPO_BRANCH="master"

ADD ./assets/etc/yum.repos.d/* /etc/yum.repos.d/
RUN yum install -y \
        epel-release \
        centos-release-gluster37 \
        centos-release-openstack-mitaka && \
    yum update -y && \
    yum install -y \
        findutils \
        python \
        python-pip \
        iproute \
        mariadb \
        mariadb-libs && \
    yum install -y \
        libxml2 \
        libxslt \
        sudo \
        lvm2 \
        parted \
        iscsi-initiator-utils \
        scsi-target-utils \
        targetcli && \
    sed -i "s|udev_rules = 1|udev_rules = 0|g" /etc/lvm/lvm.conf && \
    sed -i "s|udev_sync = 1|udev_sync = 0|g" /etc/lvm/lvm.conf && \
    yum install -y \
        gcc \
        git \
        kernel-lt \
        kernel-lt-headers \
        python-devel \
        libxml2-devel \
        libxslt-devel \
        libffi-devel \
        postgresql-devel \
        openssl-devel && \
    yum clean all && \
    mkdir -p /opt/stack && \
    git clone ${OS_REPO_URL} -b ${OS_REPO_BRANCH} --depth 1 /opt/stack/${OS_COMP} && \
    pip --no-cache-dir install crudini && \
    pip --no-cache-dir install pymysql && \
    pip --no-cache-dir install python-memcached && \
    pip --no-cache-dir install /opt/stack/${OS_COMP} && \
    mkdir -p /etc/${OS_COMP}/ && \
    mkdir -p  /opt/stack/${OS_COMP}/etc/${OS_COMP}/ && \
    cp -rf /opt/stack/${OS_COMP}/etc/${OS_COMP}/* /etc/${OS_COMP}/ && \
    mkdir -p /var/log/${OS_COMP} && \
    mkdir -p /var/lib/${OS_COMP}/lock && \
    mkdir -p /var/lib/${OS_COMP}/instances && \
    groupadd ${OS_COMP} -g 1000 && \
    adduser -u 1000 -g ${OS_COMP} --system ${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/log/${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/lib/${OS_COMP} && \
    mkdir -p /etc/cinder/volumes


ADD ./assets /opt/harbor/assets

RUN cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets
