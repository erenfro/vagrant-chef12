#!/bin/bash

## EXAMPLE Sever/Workstation Setup Process to clone existing infrastructure to local vagrant instance.


#ssh-keyscan -t rsa chef12.test.ld >> ${HOME}/.ssh/known_hosts
#ssh-keyscan -t rsa $(getent hosts chef12.test.ld | cut -d' ' -f1) >> ${HOME}/.ssh/known_hosts
#
#if [[ -d "/vagrant/Chef" ]]
#then
#	rm -rf /vagrant/Chef
#fi
#
#git clone git@chef12.test.ld:chef-repo /vagrant/Chef
#ln -s /vagrant/Chef ${HOME}/
#mkdir -p /vagrant/Chef/{cookbooks,certificates}
#
#pushd /vagrant/Chef/cookbooks >/dev/null 2>&1
#
#git clone git@chef12.test.ld:cookbook-base
#
#cd ../data_bags
#for d in */
#do
#    knife data bag create "${d%*/}"
#done
#
#cd ..
#
#knife environment from file environments/*.rb
#knife role from file roles/*.rb
#knife data bag from file -a
#knife cookbook upload -a
#
#popd >/dev/null 2>&1

echo 'eval "$(chef shell-init bash)"' >> ${HOME}/.bash_profile
echo 'KNIFE_SECRET_FILE="/vagrant/.chef/encrypted_data_bag_secret"' >> ${HOME}/.bash_profile

cat <<EOF >> ${HOME}/.bash_profile
function knife-ciphertext () {
   set KNIFE_SECRET_FILE_OFF="$KNIFE_SECRET_FILE"
   unset KNIFE_SECRET_FILE
   knife $@ --format=json
   set KNIFE_SECRET_FILE="$KNIFE_SECRET_FILE_OFF"
   unset KNIFE_SECRET_FILE_OFF
}
alias knife-ciphertext=knife-ciphertext
EOF

chef gem install kitchen-docker

