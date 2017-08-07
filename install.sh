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
setenforce 0
yum install -y docker kubelet kubeadm kubectl kubernetes-cni wget ntp
systemctl start ntpd
systemctl enable ntpd
wget http://stedolan.github.io/jq/download/linux64/jq
chmod +x ./jq
cp jq /usr/bin
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
if [ "$1" == "-master" ]; then
	kubeadm init --api-advertise-address=$2 --token=$TOKEN
  kubectl -n kube-system get ds -l 'component=kube-proxy' -o json \
  | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
  |   kubectl apply -f - && kubectl -n kube-system delete pods -l 'component=kube-proxy'
  cp /etc/kubernetes/admin.conf /shared
elif [ "$1" == "-node" ]; then
	echo "I AM A NODE"
  rm -Rf /etc/kubernetes/*
  kubeadm join $2 --token=$TOKEN
  if [ "$3" == "-last" ]; then
    kubectl --kubeconfig /shared/admin.conf apply -f https://git.io/weave-kube
    kubectl --kubeconfig /shared/admin.conf create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
  fi
fi
echo "Wait 10.00s" && sleep 10
