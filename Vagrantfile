CHEF_CLIENT_INSTALL = <<-EOF
#!/bin/bash
test -d /opt/chef || {
  echo "Installing chef-client via RPM"
  #curl -L -s https://www.opscode.com/chef/install.sh | bash -s -- -v 12.2.1
  yum -y --disableplugin=fastestmirror install https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-12.2.1-1.el6.x86_64.rpm
  #yum -y --disableplugin=fastestmirror localinstall /vagrant/rpms/chef-12.3.0-1.el6.x86_64.rpm
}
EOF

CHEF_SERVER_INSTALL = <<-EOF
#!/bin/bash

rpm -qa | grep chef-server
if [[ $? -ne 0 ]]
then
	echo "Installing Chef Server, Chef Client, and Chef-DK via RPMs"
	yum -y --disableplugin=fastestmirror install https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-12.0.8-1.el6.x86_64.rpm \
                                                 https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-12.3.0-1.el6.x86_64.rpm \
                                                 https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chefdk-0.5.1-1.el6.x86_64.rpm \
                                                 http://mirror.redsox.cc/pub/epel/6/i386/epel-release-6-8.noarch.rpm
	#yum -y --disableplugin=fastestmirror localinstall /vagrant/rpms/chef-server-core-12.0.8-1.el5.x86_64.rpm \
    #                                                  /vagrant/rpms/chef-12.3.0-1.el6.x86_64.rpm \
    #                                                  /vagrant/rpms/chefdk-0.5.1-1.el6.x86_64.rpm \
    #                                                  /vagrant/rpms/epel-release-6-8.noarch.rpm
    chef-server-ctl reconfigure
	rm -rf /vagrant/.chef
fi
EOF

CHEF_CLIENT_INIT = <<-EOF
#!/bin/bash

mkdir -p /etc/chef/trusted_certs
cp -f /vagrant/.chef/trusted_certs/* /etc/chef/trusted_certs
if [[ -f "/vagrant/secrets/encrypted_data_bag_secret" ]]
then
    cp /vagrant/secrets/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret
    chown root:root /etc/chef/encrypted_data_bag_secret
    chmod 600 /etc/chef/encrypted_data_bag_secret
fi

cat <<EOK > /etc/chef/client.rb
log_location     STDOUT
chef_server_url  "https://chef12.test.ld/organizations/vagranttest"
validation_client_name "vagranttest-validator"
# Using default node name (fqdn)
encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"
trusted_certs_dir "/etc/chef/trusted_certs"
EOK
EOF

CHEF_CREATE_ADMIN = <<-EOF
#!bin/bash

[ -f "/vagrant/.chef/knife.rb" ] && exit 0
echo "Creating workstation knife admin config"
mkdir -p /vagrant/.chef/trusted_certs
if [[ -f "/vagrant/secrets/encrypted_data_bag_secret" ]]
then
    cp /vagrant/secrets/encrypted_data_bag_secret /vagrant/.chef/encrypted_data_bag_secret
    chown vagrant:vagrant /vagrant/.chef/encrypted_data_bag_secret
    chmod 600 /vagrant/.chef/encrypted_data_bag_secret
fi

chef-server-ctl user-create vagrant Vagrant User vagrant@chef12.test.ld abs123 --filename /vagrant/.chef/vagrant.pem
chef-server-ctl org-create vagranttest Vagrant Test --association_user vagrant --filename /vagrant/.chef/chef-validator.pem

cat <<EOK > /vagrant/.chef/knife.rb
cwd                     = File.dirname(__FILE__)
log_level               :info   # valid values - :debug :info :warn :error :fatal
log_location            STDOUT
node_name               ENV.fetch('KNIFE_NODE_NAME', 'vagrant')
client_key              ENV.fetch('KNIFE_CLIENT_KEY', File.join(cwd, 'vagrant.pem'))
chef_server_url         ENV.fetch('KNIFE_CHEF_SERVER_URL', 'https://chef12.test.ld/organizations/vagranttest')
validation_client_name  ENV.fetch('KNIFE_CHEF_VALIDATION_CLIENT_NAME', 'chef-validator')
validation_key          ENV.fetch('KNIFE_CHEF_VALIDATION_KEY', File.join(cwd,'chef-validator.pem'))
syntax_check_cache_path File.join(cwd,'syntax_check_cache')
cookbook_path           File.join(cwd,'..','Chef','cookbooks')
data_bag_path           File.join(cwd,'..','Chef','data_bags')
role_path               File.join(cwd,'..','Chef','roles')
knife[:editor]          = "vim"
knife[:secret_file]     = "/vagrant/.chef/encrypted_data_bag_secret"
EOK
cp -f /var/opt/opscode/nginx/ca/chef12.test.ld.crt /vagrant/.chef/trusted_certs/
ln -s /vagrant/.chef /home/vagrant/
chown -R vagrant:vagrant /home/vagrant

yum -y install vim git docker-io

usermod -a -G docker vagrant
service docker start
EOF


VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.forward_agent = true
  config.vm.define "chef12" do |v|
    v.vm.provider "virtualbox" do |p|
      p.memory = 1024
      p.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
    v.vm.box = "chef/centos-6.6"
    v.vm.hostname = "chef12.test.ld"
    v.vm.network "private_network", ip: "192.168.248.101"
    v.vm.network "forwarded_port", guest: 443, host: 4000
    v.vm.provision :hosts
    v.vm.provision :shell, :inline => CHEF_SERVER_INSTALL
    v.vm.provision :shell, :inline => CHEF_CREATE_ADMIN
    v.vm.provision :shell, :path => "scripts/init-server.sh", privileged: false
  end
  config.vm.define "app1" do |v|
    v.vm.provider "virtualbox" do |p|
      p.memory = 512
      p.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
    v.vm.box = "chef/centos-6.6"
    v.vm.hostname = "app1.test.ld"
    v.vm.network "private_network", ip: "192.168.248.102"
    v.vm.provision :hosts
    v.vm.provision :shell, :inline => CHEF_CLIENT_INSTALL
    v.vm.provision :shell, :inline => CHEF_CLIENT_INIT
    v.vm.provision :chef_client do |chef|
      chef.chef_server_url = 'https://chef12.test.ld/organizations/vagranttest'
      chef.validation_key_path = '.chef/chef-validator.pem'
      chef.validation_client_name = 'vagranttest-validator'
      chef.run_list = [
        # ... put something in here, or knife node edit app1.test.ld
      ]
    end
  end
end

