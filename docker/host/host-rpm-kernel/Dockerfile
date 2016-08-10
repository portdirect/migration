FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%host-rpm-base:%%DOCKER_TAG%%

RUN git clone --depth 1 --branch v4.6-rc3 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git /opt/kernel

RUN cd /opt/kernel && make oldconfig
#RUN cd /opt/kernel && make menuconfig

RUN cd /opt/kernel && make rpm
