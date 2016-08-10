FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT proxy-server

RUN yum -y install \
        openstack-swift-proxy \
        git && \
    git clone --depth 1 https://github.com/openstack/swift3.git /opt/swift3 && \
    cd /opt/swift3 && python setup.py install && \
    git clone --depth 1 https://github.com/openstack/swiftonfile.git /opt/swiftonfile && \
    cd /opt/swiftonfile && python setup.py install && \
    yum autoremove -y \
        git && \
    yum clean all
RUN yum -y install \
        openstack-swift-object && \
    yum clean all

RUN yum -y install \
openstack-swift-account \
&& yum clean all
RUN yum -y install \
openstack-swift-container && \
yum clean all


COPY ./start.sh /start.sh
