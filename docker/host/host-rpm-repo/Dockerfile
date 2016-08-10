FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%host-rpm-base:%%DOCKER_TAG%%

RUN git clone --depth 1 --branch v4.6-rc3 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git /opt/kernel

RUN cd /opt/kernel && make oldconfig
#RUN cd /opt/kernel && make menuconfig

RUN cd /opt/kernel && make rpm

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    mkdir -p /srv/repo/atomic-host/7/{SRPMS,i386,x86_64,noarch} && \
    chown -R $(whoami) /srv/repo/atomic-host/7/{SRPMS,i386,x86_64,noarch}

RUN export PACKAGE_NAME="harbor-pipework" && \
    export PACKAGE_VERSION="0.1" && \
    export PACKAGE_ARCH="x86_64" && \
    export PACKAGE_URL="http://harboros.net" && \
    export ITERATIONS=$(date +%s) && \
    fpm \
    	-s dir \
    	-t rpm \
    	--after-install /opt/rpm/post-install.sh \
    	--name $PACKAGE_NAME \
    	--log info \
    	--verbose \
    	--version $PACKAGE_VERSION \
    	--iteration $ITERATIONS \
    	--architecture $PACKAGE_ARCH \
    	--epoch 1 \
    	--license "Apache 2.0" \
    	--vendor "Harbor OpenStack" \
    	--description "installation package for atomic hosts" \
    	--url $PACKAGE_URL \
    	--maintainer "Harbor OpenStack" \
    	/opt/rpm-payload && \
    cp $PACKAGE_NAME-$PACKAGE_VERSION-$ITERATIONS.$PACKAGE_ARCH.rpm /srv/repo/atomic-host/7/$PACKAGE_ARCH/

RUN ./opt/harbor/build/build-repo.sh
