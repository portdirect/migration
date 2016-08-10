FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN yum install -y \
		git \
		python-pip \
		gcc \
		python-devel \
		MySQL-python && \
	yum clean all && \
	pip install --upgrade pip

RUN mkdir -p /opt/stack && \
	git clone --depth 1 https://github.com/openstack/senlin /opt/stack/senlin

RUN sed -i 's/user = sqlalchemy.Column(sqlalchemy.String(32)/user = sqlalchemy.Column(sqlalchemy.String(64)/g' \
	/opt/stack/senlin/senlin/db/sqlalchemy/models.py

RUN sed -i "s/'user', sqlalchemy.String(32)/'user', sqlalchemy.String(64)/g" \
	/opt/stack/senlin/senlin/db/sqlalchemy/migrate_repo/versions/001_first_version.py



RUN cd /opt/stack/senlin git checkout master && \
    pip install -r requirements.txt && \
    pip install /opt/stack/senlin

RUN mkdir -p /etc/senlin && \
		cd /opt/stack/senlin && \
		cp ./etc/senlin/* /etc/senlin/

#RUN mv /etc/senlin/senlin.conf.sample /etc/senlin/senlin.conf

ADD config-senlin.sh /opt/harbor/config-senlin.sh
