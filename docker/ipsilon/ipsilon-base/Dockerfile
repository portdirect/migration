FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-ipsilon" \
    IPA_BACKED="True"

ADD ./assets/etc/yum.repos.d/infrastructure7-testing.repo /etc/yum.repos.d/infrastructure7-testing.repo

RUN yum update -y && \
    yum upgrade -y && \
    yum install -y \
				ipsilon \
				ipsilon-saml2 \
				ipsilon-authgssapi \
				ipsilon-tools-ipa \
				ipsilon-infosssd \
        sssd-dbus && \
		yum clean all

RUN yum install -y \
        postgresql && \
    yum clean all
ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
