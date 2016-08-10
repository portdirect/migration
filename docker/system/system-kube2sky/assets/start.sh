#!/bin/sh
set -e
if [ "$UNDERCLOUD" = "True" ]; then
  echo "Launching Kube2Sky for $OS_DISTRO undercloud"
  exec /kube2sky "$@"
else
  echo "$OS_DISTRO: Waiting"
  sleep 2s
  echo "$OS_DISTRO: Editing Hosts File"
  echo "$KUBERNETES_PORT_443_TCP_ADDR kubernetes.$OS_DOMAIN kubernetes" >> /etc/hosts
  sleep 1s
  echo "$OS_DISTRO: Launching Kube2Sky"
  exec /kube2sky \
    -domain=$OS_DOMAIN \
    -kube_master_url=https://kubernetes.$OS_DOMAIN \
    -kubecfg_file=/etc/harbor/auth/kubelet/kubeconfig.yaml
fi;
