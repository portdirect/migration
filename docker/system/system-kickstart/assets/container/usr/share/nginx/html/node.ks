text
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

selinux --enforcing

auth --useshadow --enablemd5

rootpw --lock --iscrypted locked

user --groups=wheel --name={{HOST_SSH_USER}} --lock --iscrypted locked --gecos="{{HOST_SSH_USER}}"


firewall --disabled
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate --onboot=on


services --enabled=sshd,rsyslog
# We use NetworkManager for anaconda, and Avahi doesn't make much sense in the cloud
services --disabled=network,avahi-daemon,cloud-init,cloud-init-local,cloud-config,cloud-final


bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8"



# Partition table
clearpart --linux --drives=sda

part /boot --size=1024 --ondisk sda
part pv.01 --size=1    --ondisk sda --grow
volgroup hah pv.01
logvol /    --vgname=hah --size=10000  --grow --name=root --fstype=xfs
logvol swap --vgname=hah --recommended --name=swap --fstype=swap
ignoredisk --only-use=sda


# Equivalent of %include fedora-repo.ks
ostreesetup --osname="harbor-host" --remote="harbor-host" --ref="harbor-host/7/x86_64/standard" --url="http://rpmostree.harboros.net:8012/repo/" --nogpg


reboot





%post --erroronfail


# Adding the public ssh key for the user
mkdir -p /home/{{HOST_SSH_USER}}
cd /home/{{HOST_SSH_USER}}
mkdir -p --mode=700 .ssh
cat >> .ssh/authorized_keys << "HARBOR_USER_PUBLIC_KEY"
{{HOST_SSH_KEY}}
HARBOR_USER_PUBLIC_KEY
chmod 600 .ssh/authorized_keys
chown -R {{HOST_SSH_USER}} /home/{{HOST_SSH_USER}}


# Enable passwordless sudo
sed -i 's/%wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tNOPASSWD: ALL/g' /etc/sudoers
# Enable sudo without tty
sed -i 's/^Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers



# older versions of livecd-tools do not follow "rootpw --lock" line above
# https://bugzilla.redhat.com/show_bug.cgi?id=964299
passwd -l root
userdel -r centos || echo "no centos user"


# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics we, like CentOS
# are differing from the Fedora default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# Fixing the locale settings
cat > /etc/environment << EOF
LANG="en_US.utf-8"
LC_ALL="en_US.utf-8"
EOF



INITIAL_DEV=$(ip addr | grep "^2:" | awk -F ':' '{print $2}')
HOSTNAME=$(ip -f link -o addr show $INITIAL_DEV | awk '{print $(NF-2)}' | tr ':' '-')
IP=$(ip -f inet -o addr show $INITIAL_DEV|cut -d\  -f 7 | cut -d/ -f 1)
curl -L -X PUT http://etcd.os-pxe.svc.port.direct:401/v2/keys/${HOSTNAME} -d value="$IP"

# REMOVE IN PRODUCTION!
cat > /etc/selinux/config <<EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF


%end
