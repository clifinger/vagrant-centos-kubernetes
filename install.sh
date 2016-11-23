#!/bin/sh

TOKEN=$4
echo 'INSTALL KUBERNETES'
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
systemctl stop  firewalld.service
systemctl disable  firewalld.service

yum list installed clusterhq-release || yum \
  install -y https://clusterhq-archive.s3.amazonaws.com/centos/clusterhq-release$(rpm -E %dist).noarch.rpm
yum install -y http://download.zfsonlinux.org/epel/zfs-release$(rpm -E %dist).noarch.rpm
gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
cat <<EOF > /etc/yum.repos.d/zfs.repo
[zfs-kmod]
name=ZFS on Linux for EL 7 - kmod
baseurl=http://download.zfsonlinux.org/epel/7/kmod/\$basearch/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
EOF
setenforce 0
yum install -y docker kubelet kubeadm kubectl kubernetes-cni wget ntp
yum install -y clusterhq-flocker-node
systemctl start ntpd
systemctl enable ntpd
wget http://stedolan.github.io/jq/download/linux64/jq
chmod +x ./jq
cp jq /usr/bin
mkdir /etc/flocker
cp /vagrant/certs/* /etc/flocker
chmod 0700 /etc/flocker && chmod 0600 /etc/flocker/*
touch /etc/flocker/env
cat <<EOF > /etc/flocker/env
FLOCKER_CONTROL_SERVICE_HOST=master
FLOCKER_CONTROL_SERVICE_PORT=4523
FLOCKER_CONTROL_SERVICE_CA_FILE=/etc/flocker/cluster.crt
FLOCKER_CONTROL_SERVICE_CLIENT_KEY_FILE=/etc/flocker/client.key
FLOCKER_CONTROL_SERVICE_CLIENT_CERT_FILE=/etc/flocker/client.crt
EOF
cat <<EOF > /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/kubernetes/kubernetes
#Requires=docker.service
#After=docker.service

[Service]
EnvironmentFile=/etc/flocker/env
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
if [ "$1" == "-master" ]; then
  systemctl enable flocker-control
  systemctl start flocker-control
	kubeadm init --api-advertise-addresses=$2 --token=$TOKEN
  kubectl -n kube-system get ds -l 'component=kube-proxy' -o json \
  | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
  |   kubectl apply -f - && kubectl -n kube-system delete pods -l 'component=kube-proxy'
  cp /etc/kubernetes/admin.conf /shared
elif [ "$1" == "-node" ]; then
  echo "$2 master" >> /etc/hosts
	echo "I AM A NODE"
  yum install -y zfs
  modprobe zfs
  echo modprobe zfs >> /etc/rc.modules
  chmo +x /etc/rc.modules
  mkdir -p /var/opt/flocker
  truncate --size 10G /var/opt/flocker/pool-vdev
  zpool create flocker /var/opt/flocker/pool-vdev
  yum install -y clusterhq-flocker-docker-plugin
  touch /etc/flocker/agent.yml
cat <<EOF > /etc/flocker/agent.yml
"version": 1
"control-service":
 "hostname": "${2}"
 "port": 4524

# The dataset key below selects and configures a dataset backend (see below: aws/openstack/etc).
# All nodes will be configured to use only one backend

dataset:
 backend: "zfs"
 pool: "flocker"
EOF
  export FLOCKER_CONTROL_SERVICE_CLIENT_CERT_FILE=/shared/certs/client/client.crt
  export FLOCKER_CONTROL_SERVICE_BASE_URL=https://master:4523/v1
  systemctl enable flocker-dataset-agent
  systemctl start flocker-dataset-agent
  systemctl enable flocker-container-agent
  systemctl start flocker-container-agent
  systemctl enable flocker-docker-plugin
  systemctl start flocker-docker-plugin
  rm -Rf /etc/kubernetes/*
  kubeadm join $2 --token=$TOKEN
  if [ "$3" == "-last" ]; then
    kubectl --kubeconfig /shared/admin.conf apply -f https://git.io/weave-kube
    kubectl --kubeconfig /shared/admin.conf create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
  fi
fi
echo "Wait 10.00s" && sleep 10
