FROM centos:7
MAINTAINER Pete Birley <petebirley@gmail.com>

# NOTE(pbourke): This is emulating the Swift "all-in-one" setups where there are 3 disks/partitions
# on which to mirror data.  This is extremely inefficient and is really only to prove everything
# works in an AIO setup. For production deploys the Ansible provisioned setup should be used.
VOLUME [ "/srv/node/sdb1" ]
VOLUME [ "/srv/node/sdb2" ]
VOLUME [ "/srv/node/sdb3" ]
