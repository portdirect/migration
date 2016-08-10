FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-murano" \
    INIT_DB_REQUIRED="True"

RUN curl https://trunk.rdoproject.org/centos7-liberty/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-liberty/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum install -y \
        python-memcached \
        git \
        python-pip \
        gcc \
        python-devel \
        postgresql-devel \
        libffi-devel \
        openssl \
        openssl-devel \
        libxml2-devel \
        libxslt-devel && \
    pip install --upgrade pip&& \
    pip install --upgrade python-openstackclient && \
    git clone --depth 1 https://github.com/openstack/murano.git /opt/murano && \
    pip install /opt/murano && \
    pip install tox && \
    mkdir -p /etc/murano && \
      cd /opt/murano && \
        tox -e genconfig && \
        cp -r etc/murano/* /etc/murano/ && \
        rm -rf /root/.cache && \
    mv /etc/murano/murano.conf.sample /etc/murano/murano.conf && \
		export MURANO_GID="188" && \
		export MURANO_UID="188" && \
		export MURANO_USER="murano" && \
		groupadd -g ${MURANO_GID} ${MURANO_USER} && \
		useradd -u ${MURANO_UID} -g ${MURANO_GID} \
				-c "${MURANO_USER} system user account" \
				-d "/var/lib/${MURANO_USER}" \
				--no-create-home \
				-s '/sbin/nologin' ${MURANO_USER}

RUN pip uninstall -y six && \
    pip install six

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
