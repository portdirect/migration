FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%centos:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="mongodb"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum install -y \
        mongodb \
        mongodb-server \
        openstack-trove-guestagent \
        python-pip \
        pymongo && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN rm -f /assets/usr/lib/python2.7/site-packages/trove/guestagent/datastore/experimental/mongodb/system.py* && \
    /bin/cp -rf /opt/harbor/assets/* / && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    echo "trove ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chmod 0440 /etc/sudoers && \
    sed -i 's/fork = true/fork = False/' /etc/mongod.conf && \
    systemctl enable mongod
