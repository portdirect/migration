FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%

ENV KURYR_REPO="https://github.com/midonet/kuryr.git" \
    KURYR_BRANCH="k8s"



RUN yum install -y \
        gcc \
        git \
        openssl-devel \
        centos-release-scl && \
    yum install -y \
            rh-python34 && \
    yum clean all && \
    git clone --depth 1 ${KURYR_REPO} -b ${KURYR_BRANCH} /opt/kuryr

ENV MANPATH="/opt/rh/rh-python34/root/usr/share/man:" \
    X_SCLS="rh-python34" \
    LD_LIBRARY_PATH="/opt/rh/rh-python34/root/usr/lib64" \
    PATH="/opt/rh/rh-python34/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    SHLVL="4" \
    XDG_DATA_DIRS="/opt/rh/rh-python34/root/usr/share" \
    PKG_CONFIG_PATH="/opt/rh/rh-python34/root/usr/lib64/pkgconfig"

RUN pip install --upgrade pip && \
    pip install --upgrade setuptools && \
    pip install --upgrade tox && \
    cd /opt/kuryr/ && \
      tox -egenconfig && \
      rm -rf .tox && \
    cd / && \
    pip install --upgrade /opt/kuryr && \
    mkdir -p /etc/kuryr && \
    cp /opt/kuryr/etc/kuryr.conf.sample /etc/kuryr/kuryr.conf && \
    cp /opt/kuryr/etc/kuryr.json /etc/kuryr/kuryr.json
