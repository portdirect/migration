#!/bin/bash
set -e
OPENSTACK_COMPONENT="Proxy"
OPENSTACK_SUBCOMPONENT="Base"
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

tail -f /dev/null
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
frontend  http_insecure
    bind :80
    mode http
    option                  httplog
    option forwardfor       except 127.0.0.0/8

    # Define hosts
    acl host_account hdr(host) -i account.${OS_DOMAIN}
    acl host_horizon hdr(host) -i api.${OS_DOMAIN}
    acl host_tenant hdr_end(host) -i .open.${OS_DOMAIN}

    # Forward to the appropriate backend
    use_backend http_account_cluster if host_account
    use_backend http_horizon_cluster if host_horizon
    use_backend http_tenant_cluster if host_tenant

    # Define the fallback backend
    default_backend             http_tenant_cluster

frontend  https_passthough
    bind :443
    mode tcp
    option                  tcplog

    # Define hosts
    acl host_tcp_ipa  req.ssl_sni -i ipa.${OS_DOMAIN}
    acl host_tcp_account  req.ssl_sni -i account.${OS_DOMAIN}
    acl host_tcp_horizon  req.ssl_sni -i api.${OS_DOMAIN}
    acl host_tcp_tenant  req.ssl_sni -m end .open.${OS_DOMAIN}

    # Reject connections if not defined
    tcp-request inspect-delay 2s
    tcp-request content reject if !host_tcp_ipa !host_tcp_account !host_tcp_horizon !host_tcp_tenant

    # Forward to the appropriate backend
    use_backend https_tcp_ipa_cluster if host_tcp_ipa
    use_backend https_tcp_account_cluster if host_tcp_account
    use_backend https_tcp_horizon_cluster if host_tcp_horizon
    use_backend https_tcp_tenant_cluster if host_tcp_tenant

    # Define the fallback backend
    default_backend             https_tcp_tenant_cluster


#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend http_account_cluster
    mode http
    balance     roundrobin
    server  app1 os-accounts.os-accounts.svc:80 check

backend http_horizon_cluster
    mode http
    balance     roundrobin
    server  app1 os-horizon-api.os-horizon.svc:80 check

backend http_tenant_cluster
    mode http
    balance     roundrobin
    server  app1 os-tenant-proxy.os-horizon.svc:80 check

backend https_tcp_ipa_cluster
    mode tcp
    server  app1 ipa.${OS_DOMAIN}:443 check

backend https_tcp_account_cluster
    mode tcp
    server  app1 os-accounts.os-accounts.svc:443 check

backend https_tcp_horizon_cluster
    mode tcp
    server  app1 os-horizon-api.os-horizon.svc:443 check

backend https_tcp_tenant_cluster
    mode tcp

    acl tenant_host_port_ext req.ssl_sni -m reg (10\.142(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){2})\-((6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{0,3}))\.open.${OS_DOMAIN}
    tcp-request content reject if !tenant_host_port_ext

    use-server tenant_host_port_int if tenant_host_port_ext
    option ssl-hello-chk
    server tenant_host_port_int os-proxy-sni.os-proxy.svc:443
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching haproxy"
################################################################################
exec haproxy -db -V -f /etc/haproxy/haproxy.cfg
