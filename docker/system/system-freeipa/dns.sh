#!/bin/sh




echo ${ADMIN_PASSWORD} | kinit admin

ipa dnsrecord-add $(hostname -d) skydns --a-rec 10.112.0.4

ipa dnsrecord-add $(hostname -d). svc --ns-rec=skydns
ipa dnsforwardzone-add  svc.$(hostname -d). --forwarder 10.112.0.4

ipa dnsrecord-add $(hostname -d). pod --ns-rec=skydns
ipa dnsforwardzone-add pod.$(hostname -d). --forwarder 10.112.0.4
