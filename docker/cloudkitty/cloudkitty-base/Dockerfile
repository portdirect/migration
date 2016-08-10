FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-cloudkitty" \
    LC_ALL="en_US.UTF-8" \
    CLOUDKITTY_GID="668" \
		CLOUDKITTY_UID="668" \
		CLOUDKITTY_USER="cloudkitty"

RUN curl https://trunk.rdoproject.org/centos7-liberty/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-liberty/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
	  yum install -y \
        git \
        gcc \
        postgresql-devel \
        libffi-devel \
        openssl \
        openssl-devel \
        libxml2-devel \
        libxslt-devel \
        mariadb-devel \
        httpd \
        httpd-devel \
        mod_ssl \
        mod_wsgi \
        python-pip \
        python-devel \
        python2-oslo-db && \
    rpm -e --nodeps centos-logos && \
    yum clean all && \
    rm -f /etc/httpd/conf.d/*.conf && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    pip install --upgrade pip && \
    git clone --depth 1 https://github.com/openstack/cloudkitty.git /opt/cloudkitty && \
    pip install /opt/cloudkitty && \
    pip install tox && \
    mkdir -p /etc/cloudkitty && \
      cd /opt/cloudkitty && \
        tox -e genconfig && \
    /bin/cp -rf /opt/cloudkitty/etc/cloudkitty/* /etc/cloudkitty && \
		groupadd -g ${CLOUDKITTY_GID} ${CLOUDKITTY_USER} || true && \
		useradd -u ${CLOUDKITTY_UID} -g ${CLOUDKITTY_GID} \
				-c "${CLOUDKITTY_USER} system user account" \
				-d "/var/lib/${CLOUDKITTY_USER}" \
				--no-create-home \
				-s '/sbin/nologin' ${CLOUDKITTY_USER} && \
    pip install --upgrade oslo.config && \
    pip uninstall -y six && \
    pip install six

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    cp -f /etc/cloudkitty/cloudkitty.conf.sample /etc/cloudkitty/cloudkitty.conf
