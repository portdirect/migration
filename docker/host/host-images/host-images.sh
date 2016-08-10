#!/bin/bash

cat > /etc/yum.repos.d/atomic7-testing.repo <<EOF
[atomic7-testing]
name=atomic7-testing
baseurl=http://cbs.centos.org/repos/atomic7-testing/x86_64/os/
gpgcheck=0
EOF

yum install -y docker libvirt rpm-ostree-toolbox epel-release

yum install -y gcc openssl-devel python-devel python-setuptools libffi-devel python-pip
pip install --upgrade pip setuptools
pip install gsutil

setenforce 0
systemctl restart libvirtd
systemctl restart docker

(
DOCKER_NAMESPACE=docker.io/port
DOCKER_PREFIX=
DOCKER_TAG=latest

DOCKER_CMD=docker
${DOCKER_CMD} pull ${DOCKER_NAMESPACE}/host-repo:${DOCKER_TAG}

REPO_IMAGE=$(docker run -d ${DOCKER_NAMESPACE}/host-repo:latest)

${DOCKER_CMD} cp ${REPO_IMAGE}:/srv/repo /srv/
${DOCKER_CMD} cp ${REPO_IMAGE}:/assets /tmp/
rm -rf  /tmp/atomic
mv -f /tmp/assets /tmp/atomic

${DOCKER_CMD} stop ${REPO_IMAGE}
${DOCKER_CMD} rm ${REPO_IMAGE}

docker run -it port/ovn-base:latest sh
nginx
sed -i "s/172.17.0.11/172.17.0.2/" /tmp/atomic/harbor-ovs.repo


iptables -I INPUT -s 192.168.122.0/24 -j ACCEPT
cd ~
rm -rf /srv/images
rpm-ostree-toolbox imagefactory \
  --ostreerepo /srv/repo \
  --tdl /tmp/atomic/base.tdl \
  -c  /tmp/atomic/config.ini \
  -i kvm \
  -k /tmp/atomic/cloud.ks \
  -o /srv/images

iptables -I INPUT -s 192.168.122.0/24 -j ACCEPT
cd ~
rm -rf /srv/images
rpm-ostree-toolbox imagefactory \
  --ostreerepo /srv/repo \
  --tdl /tmp/atomic/base.tdl \
  -c  /tmp/atomic/config.ini \
  -i raw \
  -k /tmp/atomic/cloud-gce.ks \
  -o /srv/images

cd /srv/images/images
mv harbor-host-7.raw disk.raw

# OFFSET=$(expr $(fdisk -l $(pwd)/disk.raw | grep $(pwd)/disk.raw2 | awk '{ print $2 }') \* 512)
# mkdir -p $(pwd)/working-mount
# mount -t xfs -o offset=${OFFSET} $(pwd)/disk.raw $(pwd)/working-mount
# OS_TREE_ROOT=$(find $(pwd)/working-mount | grep '/etc/passwd$' | tail -n 1 | sed "s,/etc/passwd$,,")
# sed -i "s/root:locked::0:99999:7:::/root::10852:0:99999:7:::/" ${OS_TREE_ROOT}/etc/shadow
# umount $(pwd)/working-mount
# rm -rf $(pwd)/working-mount

tar -Szcf harbor-host-7.tar.gz disk.raw
rm -rf disk.raw
)
(
gsutil mb -c durable_reduced_availability -l EU gs://harbor
gsutil rm gs://harbor/harbor-host-7.tar.gz
gsutil cp /srv/images/images/harbor-host-7.tar.gz gs://harbor


gcloud compute --project "portdirect-1" \
    images delete "harbor-host"
gcloud compute --project "portdirect-1" \
    images create "harbor-host" \
    --source-uri "https://storage.googleapis.com/harbor/harbor-host-7.tar.gz"
)

gcloud compute --project "portdirect-1" \
    instances delete "harbor-host"

gcloud compute --project "portdirect-1" \
    instances create "harbor-host" \
    --tags "core","ipa" \
    --description "harbor-host-1" \
    --zone "europe-west1-b" \
    --machine-type "n1-highmem-2" \
    --subnet "default" \
    --maintenance-policy "MIGRATE" \
    --tags "http-server","https-server" \
    --image "/portdirect-1/harbor-host" \
    --boot-disk-size "20" \
    --boot-disk-type "pd-standard" \
    --boot-disk-device-name "harbor-host" \
    --no-scopes \
    --metadata 'user-data=#!/bin/bash\u000aecho \"userdata\" > /tmp/userdata-test,startup-script=#!/bin/bash\u000aecho \"gce\" > /tmp/gce-test'






cd ~
rm -rf /srv/images
rpm-ostree-toolbox imagefactory \
  --ostreerepo /srv/repo \
  --tdl /tmp/atomic/base.tdl \
  -c  /tmp/atomic/config.ini \
  -i raw \
  -k /tmp/atomic/cloud-azure.ks \
  -o /srv/images


docker run --privileged -it --rm -v /srv/images/images:/srv/images/images:rw -v /dev:/dev port/host-images-azure:latest bash

cd /srv/images/images
MB=$((1024*1024))
size=$(qemu-img info -f raw --output json "harbor-host-7.raw" | \
        gawk 'match($0, /"virtual-size": ([0-9]+),/, val) {print val[1]}')
rounded_size=$((($size/$MB + 1)*$MB))
qemu-img resize -f raw harbor-host-7.raw $rounded_size
qemu-img convert -f raw -o subformat=fixed -O vpc harbor-host-7.raw harbor-host-7.vhd



cd /srv/images/images
mv harbor-host-7.vhd harbor-host-7-hyperv.vhd
azure vm image create "harbor-host-7-hyperv" \
--blob-url harborimages/harbor-host/harbor-host-7-hyperv.vhd \
--os Linux \
./harbor-host-7-hyperv.vhd




azure vm create  harbor-host "harbor-host-7" centos 'Password!23'



OFFSET=$(expr $(fdisk -l $(pwd)/harbor-host-7.raw  | grep $(pwd)/harbor-host-7.raw | awk '{ print $2 }' | tail -n 1) \* 512)
mkdir -p $(pwd)/working-mount
mount -t xfs -o offset=${OFFSET} $(pwd)/harbor-host-7.raw $(pwd)/working-mount
# OS_TREE_ROOT=$(find $(pwd)/working-mount | grep '/etc/passwd$' | tail -n 1 | sed "s,/etc/passwd$,,")
# sed -i "s/root:locked::0:99999:7:::/root::10852:0:99999:7:::/" ${OS_TREE_ROOT}/etc/shadow
# umount $(pwd)/working-mount
# rm -rf $(pwd)/working-mount




aws iam upload-signing-certificate --user-name petebirley@gmail.com --certificate-body file://aws-certificate.pem

cat > /tmp/trust-policy.json <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"",
         "Effect":"Allow",
         "Principal":{
            "Service":"vmie.amazonaws.com"
         },
         "Action":"sts:AssumeRole",
         "Condition":{
            "StringEquals":{
               "sts:ExternalId":"vmimport"
            }
         }
      }
   ]
}
EOF
aws iam create-role --role-name vmimport --assume-role-policy-document file:///tmp/trust-policy.json


cat > /tmp/role-policy.json <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "s3:ListBucket",
            "s3:GetBucketLocation"
         ],
         "Resource":[
            "arn:aws:s3:::harbor-host"
         ]
      },
      {
         "Effect":"Allow",
         "Action":[
            "s3:GetObject"
         ],
         "Resource":[
            "arn:aws:s3:::harbor-host/*"
         ]
      },
      {
         "Effect":"Allow",
         "Action":[
            "ec2:ModifySnapshotAttribute",
            "ec2:CopySnapshot",
            "ec2:RegisterImage",
            "ec2:Describe*"
         ],
         "Resource":"*"
      }
   ]
}
EOF
aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document file:///tmp/role-policy.json

aws s3 cp harbor-host-7-vsphere.ova s3://harbor-host/
aws s3 cp ./harbor-host-7.raw s3://harbor-host/


qemu-img convert -f raw -O vmdk harbor-host-7.raw  harbor-host-7.vmdk

cat > /tmp/containers.json <<EOF
[{
    "Description": "Harbor Host 7",
    "Format": "vmdk",
    "UserBucket": {
        "S3Bucket": "harbor-host",
        "S3Key": "harbor-host-7.vmdk"
    }
}]
EOF
aws ec2 import-image --description "harbor-host" --disk-containers file:///tmp/containers.json
aws ec2 describe-import-image-tasks --cli-input-json "{ \"ImportTaskIds\": [\"import-ami-fg37eemz\"], \"NextToken\": \"abc\", \"MaxResults\": 10 } "


ami-0b8a0878

































cd ~
rm -rf /srv/images
rpm-ostree-toolbox imagefactory \
  --ostreerepo /srv/repo \
  --tdl /tmp/atomic/base.tdl \
  -c  /tmp/atomic/config.ini \
  -i raw \
  -k /tmp/atomic/cloud-aws.ks \
  -o /srv/images

cd /srv/images/images



HARBOR_VOLUME=$(aws ec2 create-volume --volume-type gp2 --size 16 --availability-zone "eu-west-1c" --output text | awk '{print $(NF-1)}')

aws ec2 run-instances --image-id ami-01831c72 --instance-type t2.medium --key-name ec2 --security-group-ids ${HARBOR_VOLUME_SG}

aws ec2 attach-volume --volume-id ${HARBOR_VOLUME} --instance-id i-24c5ecae --device /dev/sdh

ssh -i "ec2.pem" fedora@ec2-52-30-244-9.eu-west-1.compute.amazonaws.com
scp -i "ec2.pem" /srv/images/images/harbor-host-7.raw.gz fedora@ec2-52-30-244-9.eu-west-1.compute.amazonaws.com:/home/fedora/harbor-host-7.raw.gz

ssh -i "ec2.pem" fedora@ec2-52-30-244-9.eu-west-1.compute.amazonaws.com

sudo su
gzip --stdout --decompress harbor-host-7.raw.gz | dd of=/dev/xvdh bs=10M


aws ec2 detach-volume --volume-id ${HARBOR_VOLUME} --instance-id i-24c5ecae

HARBOR_SNAPSHOT=$(aws ec2 create-snapshot --description  "harbor-host" --volume-id ${HARBOR_VOLUME} --output text | awk '{print $4}')

aws ec2 \
register-image \
--name "harbor-host" \
--description "Harbor Atomic Host (derived from CentOS 7.2)" \
--architecture x86_64 \
--virtualization-type hvm \
--root-device-name "/dev/sda1" \
--block-device-mappings "[
    {
        \"DeviceName\": \"/dev/sda1\",
        \"Ebs\": {
            \"SnapshotId\": \"${HARBOR_SNAPSHOT}\"
        }
    },
    {
        \"DeviceName\": \"/dev/sdb\",
        \"VirtualName\": \"ephemeral0\"
    }
]"

rm -rf /srv/repo
(
cat > /srv/Dockerfile <<EOF
FROM centos:7
RUN yum update -y && \
    yum install -y \
        httpd && \
    yum clean all
ADD ./images /srv/images
RUN ln -s /srv/images/ /var/www/html/images && \
    rm -f /etc/httpd/conf.d/welcome.conf

CMD /usr/sbin/httpd -DFOREGROUND
EOF
rm -rf /srv/images
docker build -t ${DOCKER_NAMESPACE}/host-images:${DOCKER_TAG} /srv/
docker push ${DOCKER_NAMESPACE}/host-images:${DOCKER_TAG}
)
