# -*- mode: ruby -*-
# vi: set ft=ruby :

# Server

$script = <<-SCRIPT
sudo yum install -y nano wget -y
echo "Install succes"
SCRIPT

Vagrant.configure("2") do |config|

  config.vm.box = 'almalinux/8'
  config.vm.provision "shell", inline: $script
  config.vm.provision "shell", path: "Unit_script.sh"
  config.ssh.username = 'root' 
  config.ssh.password = 'vagrant'
  config.ssh.insert_key = 'true'
  config.vm.define "server" do |server|

  server.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end
  server.vm.host_name = 'server'
  #server.vm.network "private_network", type: "dhcp", name: "vboxnet"
  (0..3).each do |i|
   server.vm.disk :disk, size: "5GB", name: "disk-#{i}"
  end
 end
end
