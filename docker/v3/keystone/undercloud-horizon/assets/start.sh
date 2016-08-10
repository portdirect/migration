#!/bin/sh

cfg=/opt/stack/horizon/openstack_dashboard/local/local_settings.py
cp -f /opt/stack/horizon/openstack_dashboard/local/local_settings.py.example $cfg

sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${EXPOSED_IP}\"/g" $cfg

#tail -f /dev/null

/opt/stack/horizon/manage.py collectstatic --noinput
/opt/stack/horizon/manage.py compress
/opt/stack/horizon/manage.py runserver 0.0.0.0:80
