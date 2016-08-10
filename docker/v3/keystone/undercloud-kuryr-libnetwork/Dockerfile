FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%undercloud-base:%%DOCKER_TAG%%

ENV OS_COMP="kuryr" \
    OS_REPO_URL="https://github.com/openstack/kuryr.git" \
    OS_REPO_BRANCH="master" \
    OS_COMP_1="kuryr-libnetwork" \
    OS_REPO_URL_1="https://github.com/openstack/kuryr-libnetwork.git" \
    OS_REPO_BRANCH_1="master"

RUN apk add --no-cache --virtual run-deps \
        bash \
        iproute2 \
        openvswitch \
        uwsgi-python && \
    apk add --no-cache --virtual build-deps \
        gcc \
        git \
        linux-headers \
        musl-dev \
        python-dev && \
    pip install -U pip setuptools && \
    git clone -b ${OS_REPO_BRANCH} --depth 1 ${OS_REPO_URL} /opt/${OS_COMP} && \
    git clone -b ${OS_REPO_BRANCH_1} --depth 1 ${OS_REPO_URL_1} /opt/${OS_COMP_1} && \
    pip install /opt/${OS_COMP} && \
    cp -rf /opt/${OS_COMP}/usr /opt/${OS_COMP_1}/ && \
    cd /opt/${OS_COMP_1} && \
      python setup.py install  && \
    cd / && \
    rm -rf /opt/${OS_COMP} && \
    apk del build-deps

ENV SERVICE_USER="admin" \
    SERVICE_TENANT_NAME="admin" \
    SERVICE_PASSWORD="pass" \
    IDENTITY_URL="http://127.0.0.1:35357/v2.0" \
    OS_URL="http://127.0.0.1:9696" \
    CAPABILITY_SCOPE="local" \
    LOG_LEVEL="INFO" \
    PROCESSES=2 \
    THREADS=2

ADD ./assets /opt/harbor/assets

RUN cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets
