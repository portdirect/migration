text
lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC

auth --useshadow --enablemd5
selinux --enforcing
rootpw --lock --iscrypted locked
user --name=none

firewall --disabled

bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8"

network --bootproto=dhcp --device=eth0 --activate --onboot=on
services --enabled=sshd,rsyslog,cloud-init,cloud-init-local,cloud-config,cloud-final
# We use NetworkManager, and Avahi doesn't make much sense in the cloud
services --disabled=network,avahi-daemon

zerombr

part /boot --fstype=ext4 --asprimary --size=512 --ondrive=vda
part / --fstype=xfs --asprimary --size=3072 --ondrive=vda
clearpart --all --initlabel --drives=vda

# Equivalent of %include fedora-repo.ks
ostreesetup --osname="harbor-host" --remote="harbor-host" --ref="harbor-host/7/x86_64/standard" --url="http://rpmostree.harboros.net:8012/repo/" --nogpg


reboot

%pre --erroronfail

mv $(which mkfs.xfs) /sbin/mkfs.xfs-orig
cat > /sbin/mkfs.xfs <<EOF
#!/bin/sh
/sbin/mkfs.xfs-orig -n ftype=1 \$@
EOF
chmod +x /sbin/mkfs.xfs

%end


%post --erroronfail

# For RHEL, it doesn't make sense to have a default remote configuration,
# because you need to use subscription manager.
#rm /etc/ostree/remotes.d/*.conf
#echo 'unconfigured-state=This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.' >> $(ostree admin --print-current-dir).origin

# Anaconda is writing a /etc/resolv.conf from the generating environment.
# The system should start out with an empty file.
truncate -s 0 /etc/resolv.conf

# older versions of livecd-tools do not follow "rootpw --lock" line above
# https://bugzilla.redhat.com/show_bug.cgi?id=964299
passwd -l root
# remove the user anaconda forces us to make
userdel -r none

# If you want to remove rsyslog and just use journald, remove this!
echo -n "Disabling persistent journal"
rmdir /var/log/journal/
echo .

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .


# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

echo "Removing random-seed so it's not the same in every image."
rm -f /var/lib/random-seed

echo "Packages within this cloud image:"
echo "-----------------------------------------------------------------------"
rpm -qa
echo "-----------------------------------------------------------------------"
# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*



mkdir -p /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz76eIGqMxuoAnkvIlfHZBZUisLA9hEH2/aC9GiE31MBPMavcUuCqquWMyObwupVWRVIxsd6OCLqbSHAHArhh555RRGUgsGFIVBfjXkT6r1n4lcbJEXCb3Y0x/TaxlOkXvt98jVjHwvi9Ju1zWHOfj997o3p8qDGhjfNyIxF3F0flHPXlCpqVK8HVmanSILb9soX5IVF3BC4n+pcBvBtpt5eY8uH0BC6ceDCFetuzwVgL15gB7yAG1KC+OA46XcUyP43Ts//FQtSH5TgxO/KkzLBB0VM/RHWQYycHmHflwMTk5jzdtACYrTdSqCwDCOzu1xvuX8ikMS83ln01fU2Yh root@3c-07-54-4f-ce-70.port.direct' > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys


echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
chattr -i /boot/extlinux/ldlinux.sys || true
/usr/sbin/fixfiles -R -a restore
chattr +i /boot/extlinux/ldlinux.sys || true

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
