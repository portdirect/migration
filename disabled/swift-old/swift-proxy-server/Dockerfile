FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%swift-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT proxy-server

RUN yum -y install \
        openstack-swift-proxy \
        git && \
    git clone --depth 1 https://github.com/openstack/swift3.git /swift3 && \
    cd /swift3 && python setup.py install && \
    yum autoremove -y \
        git && \
    yum clean all

COPY ./start.sh /start.sh
