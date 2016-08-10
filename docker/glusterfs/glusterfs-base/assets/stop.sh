#!/bin/sh

# Unmounting all glusterfs devices
mount | grep "on /export" | awk '{print $3}' | \
  while read MOUNT; do
    umount $MOUNT || true
  done

# Unmounting the gluster daemon-data dir
umount /var/lib/glusterd

# Tell PID 1 that its time to go
kill 1
