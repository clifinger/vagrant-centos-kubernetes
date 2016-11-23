### Install Nodes
On each Node include master

```bash
yum list installed clusterhq-release || yum install -y https://clusterhq-archive.s3.amazonaws.com/centos/clusterhq-release$(rpm -E %dist).noarch.rpm
yum install -y clusterhq-flocker-node
yum install -y clusterhq-flocker-docker-plugin
mkdir /etc/flocker
##Only for Nodes
yum install -y http://download.zfsonlinux.org/epel/zfs-release$(rpm -E %dist).noarch.rpm
gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
cat <<EOF > /etc/yum.repos.d/zfs.repo
[zfs-kmod]
name=ZFS on Linux for EL 7 - kmod
baseurl=http://download.zfsonlinux.org/epel/7/kmod/\\$basearch/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
EOF
yum install -y zfs
modprobe zfs
cp /vagrant/certs/nodes/* /etc/flocker
```

On master
```bash
yum install -y clusterhq-flocker-cli
cp /vagrant/certs/master/* /etc/flocker
systemctl enable flocker-control
systemctl start flocker-control
```
