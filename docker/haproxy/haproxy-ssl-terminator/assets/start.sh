#!/bin/sh
set -e


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
mkdir -p /etc/pki/tls/private
mkdir -p /etc/pki/tls/certs
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt
cat /etc/pki/tls/certs/ca.crt /etc/pki/tls/private/ca.key > /etc/pki/tls/private/ca.pem

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring haproxy"
################################################################################
cat > /etc/haproxy/haproxy.cfg <<EOF
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    log                     global
    option                  dontlognull
    option http-server-close
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend localhost
    bind *:${PUBLISH_HTTPS_PORT} ssl crt /etc/pki/tls/private/ca.pem
    mode http
    default_backend nodes


#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend nodes
    mode http
    balance roundrobin
    option forwardfor
    server app 127.0.0.1:${LOCAL_HTTP_PORT} check
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching haproxy"
################################################################################
exec haproxy -db -V -f /etc/haproxy/haproxy.cfg
