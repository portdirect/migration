#!/bin/bash
cfg=/etc/trove/trove-guestagent.conf
crudini --set $cfg oslo_messaging_rabbit rabbit_use_ssl "False"
crudini --set $cfg oslo_messaging_rabbit rabbit_host "{{TROVE_RABBITMQ_HOST}}"
crudini --set $cfg oslo_messaging_rabbit rabbit_port "{{TROVE_RABBITMQ_PORT}}"
crudini --set $cfg oslo_messaging_rabbit rabbit_userid "{{TROVE_RABBITMQ_USER}}"
crudini --set $cfg oslo_messaging_rabbit rabbit_password "{{TROVE_RABBITMQ_PASS}}"
