FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%undercloud-base:%%DOCKER_TAG%%

ENV OS_COMP="glance" \
    OS_REPO_URL="https://github.com/openstack/glance.git" \
    OS_REPO_BRANCH="master"

RUN cat /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache --virtual run-deps  \
        py-numpy \
        py-xattr \
        libxml2 \
        libxslt \
        libldap \
        libsasl \
        libcurl \
        openssl && \
    apk add --no-cache --virtual mnanagement-deps  \        
        mariadb-client \
        mariadb-client-libs && \
    apk add --no-cache --virtual build-deps \
        gcc \
        git \
        musl-dev \
        python-dev \
        linux-headers \
        libffi-dev \
        postgresql-dev \
        openssl-dev \
        libxml2-dev \
        libxslt-dev && \
    mkdir -p /opt/stack && \
    git clone ${OS_REPO_URL} -b ${OS_REPO_BRANCH} --depth 1 /opt/stack/${OS_COMP} && \
    pip install /opt/stack/${OS_COMP} && \
    mkdir -p /etc/${OS_COMP}/ && \
    mkdir -p  /opt/stack/${OS_COMP}/etc/ && \
    cp -rf /opt/stack/${OS_COMP}/etc/* /etc/${OS_COMP}/ && \
    apk del build-deps && \
    mkdir -p /var/log/${OS_COMP} && \
    addgroup ${OS_COMP} -g 1000 && \
    adduser -u 1000 -D -s /bin/false -G ${OS_COMP} ${OS_COMP} && \
    chown -R ${OS_COMP}:${OS_COMP} /var/log/${OS_COMP}

ADD ./assets /opt/harbor/assets

RUN cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets
