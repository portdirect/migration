#!/bin/sh
tail -f /dev/null
# Make sure that we have required directories in the host
mkdir -p /etc/cockpit/ws-certs.d
chmod 755 /etc/cockpit/ws-certs.d
chown root:root /etc/cockpit/ws-certs.d

mkdir -p /var/lib/cockpit
chmod 775 /var/lib/cockpit
chown root:wheel /var/lib/cockpit

# Ensure we have certificates

/usr/sbin/remotectl certificate --ensure
/bin/mount --bind /host/var /var


/usr/libexec/cockpit-ws
