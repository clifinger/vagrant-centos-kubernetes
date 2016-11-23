# Vagrant Centos kubernetes cluster
- Centos 7.2 amd64
- docker 1.10
- kubeadm 1.5
```
NAME                                    READY     STATUS    RESTARTS   AGE
dummy-2088944543-36vp6                  1/1       Running   0          1h
etcd-master                             1/1       Running   0          1h
kube-apiserver-master                   1/1       Running   0          1h
kube-controller-manager-master          1/1       Running   0          1h
kube-discovery-1150918428-dkdke         1/1       Running   0          1h
kube-dns-654381707-a4yey                3/3       Running   0          1h
kube-proxy-moijj                        1/1       Running   0          1h
kube-proxy-pwjfw                        1/1       Running   0          1h
kube-proxy-vicnd                        1/1       Running   0          1h
kube-scheduler-master                   1/1       Running   0          1h
kubernetes-dashboard-3203700628-stzjl   1/1       Running   0          1h
weave-net-01aay                         2/2       Running   0          1h
weave-net-eurrr                         2/2       Running   0          1h
weave-net-ph7l3                         2/2       Running   0          1h
```

## plugins
- weave-net
- dashboard

## Extra plugins
- Grafana + InfluxDB (must be activated in config.rb)
![grafana](https://cloud.githubusercontent.com/assets/3530471/20548729/e84b6756-b160-11e6-8bd6-a78eb2a95d88.png)

## Prerequisites
- Vagrant 1.8 (with NFS support)

#### Note for Windows

- The vagrant-winnfsd plugin will be installed in order to enable NFS shares.
- The project will run some bash script under the VirtualMachines. These scripts line ending need to be in LF. Git for windows set ```core.autocrlf``` true by default at the installation time. When you clone this project repository, this parameter (set to true) ask git to change all line ending to CRLF. This behavior need to be changed before cloning the repository (or after for each files by hand). We recommand to turn this to off by running ```git config --global core.autocrlf false``` and ```git config --global core.eol lf``` before cloning. Then, after cloning, do not forget to turn the behavior back if you want to run other windows projects: ```git config --global core.autocrlf true``` and ```git config --global core.eol crlf```.

## Installation
```bash
git pull https://github.com/JulienLenne/vagrant-centos-kubernetes.git
cd vagrant-centos-kubernetes/
vagrant up
```
## Clean-up
```bash
vagrant destroy
```

## Configuration
config.rb
```ruby
# If you change, Keep the structure with the dot. [0-9 a-f]
$token = "56225f.9096af3559800a6a"
# Total memory of master
$master_memory = 1536
# Increment to have more nodes
$worker_count = 2
# Total memory of nodes
$worker_memory = 1536
# Add Grafana with InfluxDB (work with heapster)
$grafana = false
```

### Basic usage
```bash
# Note : You need to have kubectl on the host
# http://kubernetes.io/docs/user-guide/prereqs/
# Or use ssh (vagrant ssh master)
# If you use SSH to connect on master you should remove
# "--kubeconfig admin.conf" argument
# Cluster info
kubectl cluster-info --kubeconfig admin.conf
# Get nodes
kubectl get nodes --kubeconfig admin.conf
# Get system pods
kubectl get pods --namespace=kube-system --kubeconfig admin.conf
# Go to dashboard (require kubectl on the host, or use master
# ip address to access to the ui)
kubectl proxy --kubeconfig admin.conf # http://localhost:8001/ui on host
## Full documentation : http://kubernetes.io/docs/
```

### Next features
- Can add more master
- Can add more etcd
- Include flocker with full support of ZFS
