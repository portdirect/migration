FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%foreman-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="proxy"


RUN yum install -y \
        OpenIPMI-modalias \
        bind-libs-lite \
        dhcp \
        dhcp-common \
        dhcp-libs \
        foreman-debug \
        foreman-proxy \
        initscripts \
        ipmitool \
        mtools \
        rsync \
        rubygem-bundler \
        rubygem-bundler_ext \
        rubygem-ffi \
        rubygem-gssapi \
        rubygem-net-http-persistent \
        rubygem-rack \
        rubygem-rack-protection \
        rubygem-rake \
        rubygem-rkerberos \
        rubygem-rubyipmi \
        rubygem-sinatra \
        rubygem-thor \
        rubygem-tilt \
        sudo \
        syslinux \
        sysvinit-tools \
        tftp-server \
        wget \
        xinetd && \
    yum clean all

RUN mkdir -p /var/lib/tftpboot/boot && \
    curl -L http://downloads.theforeman.org/discovery/releases/latest/fdi-image-latest.tar > /opt/fdi-image-latest.tar

RUN curl -L http://dl.fedoraproject.org/pub/alt/atomic/stable/Cloud_Atomic/x86_64/os/images/pxeboot/initrd.img > /opt/CentOS-7.2-x86_64-initrd.img && \
    curl -L http://dl.fedoraproject.org/pub/alt/atomic/stable/Cloud_Atomic/x86_64/os/images/pxeboot/vmlinuz > /opt/CentOS-7.2-x86_64-vmlinuz

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    systemctl mask ipmievd.service && \
    curl -L https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework > /usr/bin/pipework && \
    chmod +x /usr/bin/pipework && \
    mkdir -p /var/lib/tftpboot/boot

ENV LANG=en_US.UTF-8
