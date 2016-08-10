FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%cinder-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT volume

RUN yum install -y \
        parted \
        scsi-target-utils \
        targetcli && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
