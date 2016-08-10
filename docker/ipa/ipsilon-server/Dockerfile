FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-ipsilon" \
    IPA_BACKED="True"

RUN yum install -y \
				ipsilon \
				ipsilon-saml2 \
				ipsilon-authgssapi \
				ipsilon-tools-ipa \
				ipsilon-infosssd && \
		yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
