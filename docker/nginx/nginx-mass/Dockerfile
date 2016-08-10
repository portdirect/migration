FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nginx-base:%%DOCKER_TAG%%

RUN yum install -y \
        git \
        dnsutils \
        bind-utils && \
    yum groupinstall -y \
        'Development Tools' && \
    yum clean all && \
    git clone --depth 1 git://git.code.sf.net/p/rgxg/code rgxg-code && \
    cd rgxg-code/ && \
        sh ./autogen.sh && \
        ./configure && \
        make && \
        make install && \
    yum groupremove -y \
        'Development Tools' && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
