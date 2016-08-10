#!/bin/bash
set -e
: ${OS_DOMAIN:="$(hostname -d)"}
: ${OS_HOSTNAME_SHORT:="freeipa-master"}

################################################################################
echo "${OS_DISTRO}: Generating local environment file from secrets_dir"
################################################################################
SECRETS_DIR=/etc/os-config
find $SECRETS_DIR -type f -printf "\n#%p\n" -exec bash -c "cat {} | sed 's|\\\n$||g'" \; > /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


MASTER_IPA_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${OS_HOSTNAME_SHORT})
################################################################################
echo "${OS_DISTRO}: Setting Master IPA Endpoint to ${MASTER_IPA_IP}"
################################################################################
cat > /tmp/freeipa-master-endpoint.yaml <<EOF
apiVersion: "v1"
kind: "Endpoints"
metadata:
  labels:
    harbor-app: freeipa-master
  name: freeipa-master
  namespace: harbor-freeipa
subsets:
 - addresses:
      - ip: "${MASTER_IPA_IP}"
   ports:
      - port: 443
        protocol: TCP
        name: https
      - port: 80
        protocol: TCP
        name: http
      - port: 53
        protocol: TCP
        name: dns
      - port: 53
        protocol: UDP
        name: dns-udp
      - port: 389
        protocol: TCP
        name: ldap
      - port: 636
        protocol: UDP
        name: ldaps
      - port: 88
        protocol: TCP
        name: kerb
      - port: 88
        protocol: UDP
        name: kerb-udp
      - port: 464
        protocol: TCP
        name: kerb-pwd
      - port: 464
        protocol: UDP
        name: kerb-pwd-udp
      - port: 123
        protocol: UDP
        name: ntp
      - port: 7389
        protocol: TCP
        name: ipa-ldap
      - port: 9443
        protocol: TCP
        name: dogtag-agent
      - port: 9444
        protocol: TCP
        name: dogtag-user
      - port: 9445
        protocol: TCP
        name: dogtag-admin
EOF
kubectl delete -f /tmp/freeipa-master-endpoint.yaml --namespace=harbor-freeipa || echo "Did not delete endpoint"
kubectl create -f /tmp/freeipa-master-endpoint.yaml --namespace=harbor-freeipa
kubectl describe svc freeipa-master --namespace=harbor-freeipa


################################################################################
echo "${OS_DISTRO}: Monitoring IPA Server"
################################################################################
docker logs -f ${OS_HOSTNAME_SHORT}
