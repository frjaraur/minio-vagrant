# -*- mode: ruby -*-
# vi: set ft=ruby :
#
#
 VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

# Require YAML module
require 'yaml'

config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yml'))

base_box=config['environment']['base_box']

start_minion_containers=""

swarm_master_ip=config['environment']['masterip']

domain=config['environment']['domain']

engine_version=domain=config['environment']['engine_version']

boxes = config['boxes']
shared_mount=config['environment']['shared_mount']

boxes_hostsfile_entries=""
boxes_minio_server_entries=""

boxes.each do |box|
   boxes_hostsfile_entries=boxes_hostsfile_entries+box['mgmt_ip'] + ' ' +  box['name'] + ' ' + box['name']+'.'+domain+'\n'
end

#puts boxes_hostsfile_entries

update_hosts = <<SCRIPT
    echo "127.0.0.1 localhost" >/etc/hosts
    echo -e "#{boxes_hostsfile_entries}" |tee -a /etc/hosts
SCRIPT


$install_docker_engine = <<SCRIPT
  DEBIAN_FRONTEND=noninteractive apt-get remove -qq docker docker-engine docker.io
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -qq \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | DEBIAN_FRONTEND=noninteractive apt-key add -
  add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
  DEBIAN_FRONTEND=noninteractive apt-get -qq update
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce=$1
  usermod -aG docker ubuntu 2>/dev/null
SCRIPT

boxes.each do |box|
   boxes_minio_server_entries=boxes_minio_server_entries+'http://'+box['mgmt_ip'] + shared_mount + ' '
end

install_minio = <<SCRIPT
 curl -o /usr/local/bin/minio -sSL https://dl.minio.io/server/minio/release/linux-amd64/minio
 curl -o /usr/local/bin/mc -sSL https://dl.minio.io/client/mc/release/linux-amd64/mc
 curl -o /etc/systemd/system/minio.service.tmp -sSL https://raw.githubusercontent.com/minio/minio-service/master/linux-systemd/minio.service
 chmod 755 /usr/local/bin/minio /usr/local/bin/mc
 #Fix error for ubuntu
 #sed -i "s/defaults/default/g" /etc/systemd/system/minio.service
 grep -v ExecStartPre /etc/systemd/system/minio.service.tmp >/etc/systemd/system/minio.service
 echo "MINIO_VOLUMES=\"#{boxes_minio_server_entries}\""| tee -a /etc/default/minio
 echo "MINIO_ACCESS_KEY=MINIO-ACCESS-KEY"| tee -a /etc/default/minio
 echo "MINIO_SECRET_KEY=MINIO-SECRET-KEY"| tee -a /etc/default/minio
 useradd -m -s /sbin/nologin minio-user
 systemctl daemon-reload
 #systemctl enable minio.service
 #systemctl start minio.service
SCRIPT

prepare_disk = <<SCRIPT
 mkdir /mnt/data
 mkfs.ext4 -F /dev/sdc
 mount /dev/sdc #{shared_mount}
 chmod 777  #{shared_mount}
SCRIPT


# Must refactor but now it works :|
start_minion_containers = <<SCRIPT
 docker run --name minio -d \
 -e MINIO_ACCESS_KEY=MINIO-ACCESS-KEY \
 -e MINIO_SECRET_KEY=MINIO.SECRET-KEY \
 --net=host minio/minio server \
 http://minio-1/data \
 http://minio-2/data \
 http://minio-3/data \
 http://minio-4/data
SCRIPT


Vagrant.configure(2) do |config|
  config.vm.box = base_box
  config.vm.synced_folder "tmp_deploying_stage/", "/tmp_deploying_stage",create:true
  config.vm.synced_folder "src/", "/src",create:true
  boxes.each do |node|
    config.vm.define node['name'] do |config|
      config.vm.hostname = node['name']
      config.vm.provider "virtualbox" do |v|
        config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"       
	v.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
        v.name = node['name']
        v.customize ["modifyvm", :id, "--memory", node['mem']]
        v.customize ["modifyvm", :id, "--cpus", node['cpu']]
        v.customize ["modifyvm", :id, "--nictype1", "Am79C973"]
        v.customize ["modifyvm", :id, "--nictype2", "Am79C973"]
        v.customize ["modifyvm", :id, "--nictype3", "Am79C973"]
        v.customize ["modifyvm", :id, "--nictype4", "Am79C973"]
        v.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
        v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
        v.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
        v.customize ["modifyvm", :id, "--nicpromisc4", "allow-all"]
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]

        if node['role'] != "client"
            data_disk_file = File.join(VAGRANT_ROOT, node['name'] + '-data.vdi')
            unless File.exist?(data_disk_file)
            v.customize ['createhd', '--filename', data_disk_file, '--size', 500 * 1024]
            end
            v.customize ['storageattach', :id, '--storagectl', 'SCSI', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', data_disk_file]
        end

        if node['role'] == "client"
          v.gui = true
          v.customize ["modifyvm", :id, "--vram", "64"]
        end
      end

      config.vm.network "private_network",
      ip: node['mgmt_ip'],
      virtualbox__intnet: "LABS"


      config.vm.network "forwarded_port", guest: 9000, host: 9000, auto_correct: true

      #config.vm.network "public_network",
      #bridge: ["enp4s0","wlp3s0","enp3s0f1","wlp2s0"],
      #auto_config: true

      config.vm.provision "shell", inline: <<-SHELL
        sudo apt-get update -qq && apt-get install -qq ntpdate ntp && timedatectl set-timezone Europe/Madrid
      SHELL

      config.vm.provision :shell, :inline => update_hosts

      config.vm.provision "shell", inline: <<-SHELL
        sudo cp -R /src ~ubuntu
        sudo chown -R ubuntu:ubuntu ~ubuntu/src
      SHELL
 
      if node['role'] == "client"
        config.vm.provision "shell", inline: <<-SHELL
            echo "ubuntu:ubuntu"|sudo chpasswd
            DEBIAN_FRONTEND=noninteractive apt-get install -qq xserver-xorg-legacy \
            xfce4-session xfce4-terminal xfce4-xkb-plugin xterm curl xinit firefox unzip zip gpm mlocate console-common chromium-browser
            service gpm start
            update-rc.d gpm enable
            localectl set-x11-keymap es
            localectl set-keymap es
            setxkbmap -layout es
            echo -e "XKBLAYOUT=\"es\"\nXKBMODEL=\"pc105\"\nXKBVARIANT=\"\"\nXKBOPTIONS=\"lv3:ralt_switch,terminate:ctrl_alt_bksp\"" >/etc/default/keyboard
            echo '@setxkbmap -layout "es"'|tee -a /etc/xdg/xfce4/xinitrc
        SHELL

        config.vm.provision "shell", inline: "sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config"
            #echo '@setxkbmap -option lv3:ralt_switch,terminate:ctrl_alt_bksp "es"' | sudo tee -a /etc/xdg/lxsession/LXDE/autostart
            #echo '@setxkbmap -layout "es"'|tee -a /etc/xdg/lxsession/LXDE/autostart
              next
      end

      config.vm.provision :shell, :inline => prepare_disk

      ## INSTALLDOCKER --> on script because we can reprovision
      config.vm.provision "shell" do |s|
     		s.name       = "Install Docker Engine version "+engine_version
        	s.inline     = $install_docker_engine
           	s.args       = engine_version
      end

      config.vm.provision :shell, :inline => install_minio

      config.vm.provision "file", source: "create_cluster.sh", destination: "/tmp/create_cluster.sh"
      config.vm.provision :shell, :path => 'create_cluster.sh' , :args => [ node['mgmt_ip'], node['role'], swarm_master_ip ]

      config.vm.provision :shell, :inline => start_minion_containers

    end
  end

end
