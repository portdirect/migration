FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%trove-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="taskmanager"

RUN yum install -y \
        openstack-trove-taskmanager \
        python-pip && \
	  yum clean all && \
    pip install --upgrade pip && \
    pip install --upgrade python-novaclient && \
    pip install --upgrade python-openstackclient

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    rm -f /usr/lib/python2.7/site-packages/trove/taskmanager/models.pyc && \
    rm -f /usr/lib/python2.7/site-packages/trove/taskmanager/models.pyo && \
    chown trove /usr/lib/python2.7/site-packages/trove/taskmanager/models.py
