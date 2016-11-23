
# -*- mode: ruby -*-
# vi: set ft=ruby :

load 'config.rb'

def workerIP(num)
  return "172.16.78.#{num+250}"
end

VAGRANTFILE_API_VERSION = "2"

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end
  ip = "172.16.78.250"
  config.vm.box = "centos/7"
  config.vm.synced_folder ".", "/shared", type: "nfs"
  config.vm.define "master" do |master|
    master.vm.network :private_network, :ip => "#{ip}"
    master.vm.hostname = "master"
    master.vm.provider "virtualbox" do |v|
      v.memory = $master_memory
    end
    master.vm.provision :shell, :inline => "sed 's/127.0.0.1.*master/#{ip} master/' -i /etc/hosts"
    master.vm.provision :shell do |s|
      s.inline = "sh /vagrant/install.sh $1 $2 $3 $4"
      s.args = ["-master", "#{ip}", "none", "#{$token}"]
    end
  end
  (1..$worker_count).each do |i|
    config.vm.define vm_name = "node-%d" % i do |node|
      node.vm.network :private_network, :ip => "#{workerIP(i)}"
      node.vm.hostname = vm_name
      node.vm.provider "virtualbox" do |v|
        v.memory = $worker_memory
      end
      node.vm.provision :shell, :inline => "sed 's/127.0.0.1.*node-#{i}/#{workerIP(i)} node-#{i}/' -i /etc/hosts"
      node.vm.provision :shell do |s|
        s.inline = "sh /vagrant/install.sh $1 $2 $3 $4"
        if i == $worker_count
          s.args = ["-node", "#{ip}", "-last", "#{$token}"]
          #EXTRA ADDONS
          if $grafana
            node.vm.provision :shell, :inline => "kubectl --kubeconfig /shared/admin.conf apply -f /vagrant/influxdb/"
          end
        else
          s.args = ["-node", "#{ip}", "none", "#{$token}"]
        end
      end
    end
  end

end
