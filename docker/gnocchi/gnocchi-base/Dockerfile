FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-gnocchi" \
    LC_ALL="en_US.UTF-8" \
    GNOCCHI_GID="667" \
		GNOCCHI_UID="667" \
		GNOCCHI_USER="gnocchi"

ADD ./assets/etc/yum.repos.d/group_python-python3_epel7.repo /etc/yum.repos.d/group_python-python3_epel7.repo

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
	  yum install -y \
        git \
        gcc \
        gcc-c++ \
        postgresql-devel \
        libffi-devel \
        openssl \
        openssl-devel \
        libxml2-devel \
        libxslt-devel \
        mariadb-devel \
        python34 \
        python34-devel \
        python34-numpy \
        python34-Cython \
        python-lz4 \
        python-pandas \
        python-werkzeug \
        python-sqlalchemy \
        python-sqlalchemy-utils \
        httpd \
        httpd-devel \
        mod_auth_kerb \
        mod_ssl \
        mod_wsgi && \
    rpm -e --nodeps centos-logos && \
    yum clean all && \
    curl -L https://bootstrap.pypa.io/get-pip.py | /usr/bin/python3.4 && \
    pip install --upgrade pip && \
    pip install \
        mod_wsgi \
        oslo.db \
        tooz \
        lz4 \
        sqlalchemy-utils \
        mysqlclient \
        pymysql \
        python-swiftclient \
        python-keystoneclient \
        singledispatch && \
    mod_wsgi-express install-module && \
    rm -f /etc/httpd/conf.d/*.conf && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    git clone --depth 1 https://github.com/openstack/gnocchi.git /opt/gnocchi && \
    pip install /opt/gnocchi && \
    pip install tox && \
        mkdir -p /etc/gnocchi && \
          cd /opt/gnocchi && \
            tox -e genconfig && \
    mkdir -p /etc/gnocchi && \
    /bin/cp -rf /opt/gnocchi/etc/gnocchi/* /etc/gnocchi && \
		groupadd -g ${GNOCCHI_GID} ${GNOCCHI_USER} || true && \
		useradd -u ${GNOCCHI_UID} -g ${GNOCCHI_GID} \
				-c "${GNOCCHI_USER} system user account" \
				-d "/var/lib/${GNOCCHI_USER}" \
				--no-create-home \
				-s '/sbin/nologin' ${GNOCCHI_USER}

RUN curl -L https://raw.githubusercontent.com/openstack/oslo.serialization/da1475a28fa39c568b4c78e8088e61c05b747bba/oslo_serialization/msgpackutils.py > /usr/lib/python3.4/site-packages/oslo_serialization/msgpackutils.py && \
    chmod 0755 /usr/lib/python3.4/site-packages/oslo_serialization/msgpackutils.py && \
    chmod +x /usr/lib/python3.4/site-packages/oslo_serialization/msgpackutils.py

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
