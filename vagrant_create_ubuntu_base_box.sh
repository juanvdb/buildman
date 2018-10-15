#! /bin/bash

echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

sudo apt -y install linux-headers-"$(uname -r)" build-essential dkms vim openssh-server ssh net-tools gcc make

env EDITOR=vim
# sudo update-alternatives --config editor
export EDITOR=vim
#env | grep EDITOR
#sudo EDITOR=vim visudo
# Finally, you can also add a line to your /etc/sudoers file near the top that reads:
# Defaults editor=/usr/bin/vim
echo "Defaults editor=/usr/bin/vim" | sudo tee -a /etc/sudoers

if [[ -d "/media/vagrant/VBox_GAs_5.2.18" ]]; then
  sudo /media/vagrant/VBox_GAs_5.2.18/VBoxLinuxAdditions.run
else
  sudo /opt/VBoxGuestAdditions*/init/vboxadd setup
fi

# sudo vim /etc/hosts
# echo "172.28.128.1 vbhost128" | sudo tee -a /etc/hosts
sudo sed -i '$a 172.28.128.1 vbhost128' /etc/hosts
sudo sed -i '$a 192.168.56.1 vbhost56' /etc/hosts


mkdir -p /home/vagrant/.ssh
wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
# Ensure we have the correct permissions set
chmod 0700 /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# sudo vi /etc/ssh/sshd_config
sudo sed -i -e 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#PubkeyAuthentication yes/PubKeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i -e 's^#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2^AuthorizedKeysFile %h/.ssh/authorized_keys^g' /etc/ssh/sshd_config
sudo sed -i -e 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sudo service ssh restart

# if /data exist
if [[ -d /data ]]; then
  sudo chown -R $USER:$USER /data
fi

sudo dpkg --configure -a
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade
sudo apt -y clean
sudo apt -y autoremove
sudo /opt/VBoxGuestAdditions*/init/vboxadd setup

sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY

# Shutdown the machine
# sudo shutdown -h now

# Disable lock screen and power display off
echo "Disable lock screen and power display off"
echo
# Stop auto updates
echo "Stop auto updates, run:"
echo "# sudo software-properties-kde"
echo "# sudo software-properties-gtk"
echo
# Rebuild the vagrant box
echo "Run:
# vboxmanage list runningvms

# ../../reBuildVagrantImage.sh <Vagrant Box name> <Virtual Box VM name>"

exit;
