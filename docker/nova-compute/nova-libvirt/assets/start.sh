#!/bin/bash
set -e
tail -f /dev/null
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: Enableing kvm"
################################################################################
if [[ $(cat /proc/cpuinfo | grep vmx) ]]; then
    modprobe -r kvm_intel || true
  	modprobe kvm_intel nested=1
elif [[ $(cat /proc/cpuinfo | grep svm) ]]; then
    modprobe kvm_amd
else
    echo "WARNING: Your hardware does not support hardware virtualization -" \
         "using qemu software virtualization instead"
fi


################################################################################
echo "${OS_DISTRO}: Enableing ip_tables"
################################################################################
modprobe ip6_tables ip_tables ebtable_nat


################################################################################
echo "${OS_DISTRO}: Setting permissions for kvm"
################################################################################
# If libvirt is not installed on the host permissions need to be set
# If running in qemu, we don't need to set anything as /dev/kvm won't exist
if [[ -c /dev/kvm ]]; then
    chmod 660 /dev/kvm
    chown root:kvm /dev/kvm
fi


################################################################################
echo "${OS_DISTRO}: Ensuring ptmx device has correct permissions"
################################################################################
# Make sure that the ptmx device has correct permissions,
# sometimes CentOS still seems to do crazy things.
# https://bugzilla.redhat.com/show_bug.cgi?id=516120,
if [[ -c /dev/pts/ptmx ]]; then
    chmod 0666 /dev/pts/ptmx
fi

################################################################################
echo "${OS_DISTRO}: Starting Libvirt Logging"
################################################################################
/usr/sbin/virtlogd -d


################################################################################
echo "${OS_DISTRO}: Starting Libvirt"
################################################################################
exec /usr/sbin/libvirtd
