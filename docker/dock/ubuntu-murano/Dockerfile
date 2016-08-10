FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ubuntu:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="murano-agent"

RUN sed -i 's/exit 0/exit 101/' /usr/sbin/policy-rc.d && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
        murano-agent \
        subversion \
        git-core \
        wget \
        make \
        gcc \
        python-pip \
        python-dev \
        python-setuptools \
        python-virtualenv \
        iptables && \
    apt-get clean all && \
    mkdir -p /var/lock/murano /var/log/murano /var/lib/murano && \
    chown root:root /var/lock/murano /var/log/murano /var/lib/murano

ADD ./assets /opt/harbor/assets
RUN mv /sbin/iptables /sbin/.iptables && \
    /bin/cp -rf /opt/harbor/assets/* / && \
    rm -f /etc/init.d/murano-agent && \
    systemctl disable murano-agent && \
    ln -s /usr/bin/muranoagent /usr/local/bin/muranoagent && \
    sed -i 's/exit 101/exit 0/' /usr/sbin/policy-rc.d && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    echo "murano-agent ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chmod 0440 /etc/sudoers
