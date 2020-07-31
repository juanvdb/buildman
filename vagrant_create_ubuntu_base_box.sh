#! /bin/bash

echo -en "\e[7;40;37mSudo Password               \e[0m\n"
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

echo -en "\e[7;40;37mAdd user to vboxusers       \e[0m\n"
sudo usermod -a -G vboxusers $USER

echo -en "\e[7;40;37mssh package install         \e[0m\n"
sudo apt -y install ssh

echo -en "\e[7;40;37mAdd Host to /etc/hosts      \e[0m\n"
# sudo vim /etc/hosts
# echo "172.28.128.1 vbhost128" | sudo tee -a /etc/hosts
sudo sed -i '$a 172.28.128.1 vbhost128' /etc/hosts
sudo sed -i '$a 192.168.56.1 vbhost56' /etc/hosts

if [[ $USER == "vagrant" ]]; then
  echo -en "\e[7;40;37mAdd ssh keys                \e[0m\n"
  mkdir -p /home/vagrant/.ssh
  wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
  # Ensure we have the correct permissions set
  chmod 0700 /home/vagrant/.ssh
  chmod 0600 /home/vagrant/.ssh/authorized_keys
  chown -R vagrant /home/vagrant/.ssh

  echo -en "\e[7;40;37mssh Copy ID to host         \e[0m\n"
  read -rp "$1 Please enter juan@172.28.128.1 password to continue." password
  echo "$password" | ssh-copy-id juan@172.28.128.1
fi

echo -en "\e[7;40;37mFix ssh credentials         \e[0m\n"
# sudo vi /etc/ssh/sshd_config
sudo sed -i -e 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#PubkeyAuthentication yes/PubKeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i -e 's^#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2^AuthorizedKeysFile %h/.ssh/authorized_keys^g' /etc/ssh/sshd_config
sudo sed -i -e 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sudo service ssh restart

# echo -en "\e[7;40;37mRsync packages from host      \e[0m\n"
# sudo rsync -axP --exclude="lock" --exclude="partial" juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/archives/ /var/cache/apt/archives/

echo -en "\e[7;40;37mInitial Install             \e[0m\n"
sudo apt -y install linux-headers-"$(uname -r)" build-essential dkms virtualbox-guest-dkms vim openssh-server ssh net-tools gcc make perl

echo -en "\e[7;40;37mSet Vim editor              \e[0m\n"
env EDITOR=vim
# sudo update-alternatives --config editor
export EDITOR=vim
#env | grep EDITOR
#sudo EDITOR=vim visudo
# Finally, you can also add a line to your /etc/sudoers file near the top that reads:
# Defaults editor=/usr/bin/vim
echo "Defaults editor=/usr/bin/vim" | sudo tee -a /etc/sudoers

echo -en "\e[7;40;37mInstall VBox Additions      \e[0m\n"
if [[ -d "/media/vagrant/VBox*" ]]; then
  sudo /media/vagrant/VBox*/VBoxLinuxAdditions.run
else
  sudo /opt/VBoxGuestAdditions*/init/vboxadd setup
fi

echo -en "\e[7;40;37mChange /data ownership      \e[0m\n"
# if /data exist
if [[ -d /data ]]; then
  sudo chown -R $USER:$USER /data
fi

echo -en "\e[7;40;37mPackage updates             \e[0m\n"
sudo dpkg --configure -a
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade
# sudo apt -y clean
sudo apt -y autoremove
echo -en "\e[7;40;37mUpdate VBox Additions      \e[0m\n"
sudo /opt/VBoxGuestAdditions*/init/vboxadd setup

echo -en "\e[7;40;37mRsync packages to host      \e[0m\n"
rsync -axP --exclude="lock" --exclude="partial" /var/cache/apt/archives/ juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/archives/
sudo apt -y clean

echo -en "\e[7;40;37mClean and Empty disk        \e[0m\n"
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY

# Shutdown the machine
# sudo shutdown -h now

echo -en "\e[7;40;37mManual changes              \e[0m\n"
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
