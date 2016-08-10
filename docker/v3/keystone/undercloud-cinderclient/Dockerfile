FROM centos:latest

ENV OS_COMP="brick-cinderclient-ext" \
    OS_REPO_URL="https://github.com/openstack/python-brick-cinderclient-ext.git" \
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
        iproute && \
    yum install -y \
        libffi \
        libffi-devel \
        libxml2 \
        libxslt \
        sudo \
        git \
        sysfsutils \
        scsi-target-utils \
        iscsi-initiator-utils \
        targetcli \
        file \
        xfsprogs \
        e2fsprogs && \
    yum install -y \
        gcc \
        git \
        kernel-lt \
        kernel-lt-headers \
        python-devel \
        libxml2-devel \
        libxslt-devel \
        postgresql-devel \
        openssl-devel && \
    yum clean all && \
    mkdir -p /opt/stack && \
    git clone ${OS_REPO_URL} -b ${OS_REPO_BRANCH} --depth 1 /opt/stack/${OS_COMP} && \
    cd /opt/stack/${OS_COMP} && \
        git fetch git://git.openstack.org/openstack/python-brick-cinderclient-ext refs/changes/44/263744/21 && \
        git checkout FETCH_HEAD && \
        pip install -r requirements.txt && \
        python setup.py install && \
        cd / && \
    DEV_YUM_TX="$(yum history package-list kernel-lt | tail -n2 | head -n1 | awk '{ print $1 }')" && \
    yum history -y undo ${DEV_YUM_TX} && \
    mkdir -p /var/log/${OS_COMP} && \
    groupadd ${OS_COMP} -g 1000 && \
    adduser -u 1000 -g ${OS_COMP} --system ${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/log/${OS_COMP}

WORKDIR /opt/stack/${OS_COMP}
