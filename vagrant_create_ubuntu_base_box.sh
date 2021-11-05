#! /bin/bash

echo -en "\e[7;40;37m\nSudo Password               \e[0m\n"
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

echo -en "\e[7;40;37m\nInitial Pacages Install             \e[0m\n"
sudo apt -y install linux-headers-"$(uname -r)" build-essential dkms vim openssh-server ssh nfs-common net-tools gcc make perl git
# Removed virtualbox-guest-dkms

echo -en "\e[7;40;37m\nAdd user to vboxusers and nordvpn       \e[0m\n"
sudo addgroup vboxusers
sudo usermod -aG vboxusers $USER
sudo addgroup nordvpn
sudo usermod -aG nordvpn $USER
read -rp "Do you want to reboot (y/n)?" answer
if [[ $answer = [Yy1] ]]; then
  sudo reboot
fi
answer=NULL

echo -en "\e[7;40;37m\nAdd Host to /etc/hosts      \e[0m\n"
# sudo vim /etc/hosts
# echo "172.28.128.1 vbhost128" | sudo tee -a /etc/hosts
sudo sed -i '$a 172.28.128.1 vbhost128' /etc/hosts
sudo sed -i '$a 192.168.56.1 vbhost56' /etc/hosts

if [[ $USER == "vagrant" ]]; then
  echo -en "\e[7;40;37m\nAdd ssh keys                \e[0m\n"
  mkdir -p /home/vagrant/.ssh
  wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
  # Ensure we have the correct permissions set
  chmod 0700 /home/vagrant/.ssh
  chmod 0600 /home/vagrant/.ssh/authorized_keys
  chown -R vagrant /home/vagrant/.ssh

  echo -en "\e[7;40;37m\nssh Copy ID to host         \e[0m\n"
  read -rp "$1 Please enter juan@172.28.128.1 password to continue." password
  echo "$password" | ssh-copy-id juan@172.28.128.1
fi

echo -en "\e[7;40;37m\nFix ssh credentials         \e[0m\n"
# sudo vi /etc/ssh/sshd_config
sudo sed -i -e 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#PubkeyAuthentication yes/PubKeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i -e 's^#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2^AuthorizedKeysFile %h/.ssh/authorized_keys^g' /etc/ssh/sshd_config
sudo sed -i -e 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sudo service ssh restart

# echo -en "\e[7;40;37m\nRsync packages from host      \e[0m\n"
# sudo rsync -axP --exclude="lock" --exclude="partial" juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/archives/ /var/cache/apt/archives/

echo -en "\e[7;40;37m\nSet Vim editor              \e[0m\n"
env EDITOR=vim
# sudo update-alternatives --config editor
export EDITOR=vim
#env | grep EDITOR
#sudo EDITOR=vim visudo
# Finally, you can also add a line to your /etc/sudoers file near the top that reads:
# Defaults editor=/usr/bin/vim
echo "Defaults editor=/usr/bin/vim" | sudo tee -a /etc/sudoers

echo -en "\e[7;40;37m\nInstall VBox Additions      \e[0m\n"
vBoxVersion=$(ls /media/$USER)
if [[ -d "/media/$USER/$vBoxVersion" ]]; then
  sudo "/media/$USER/$vBoxVersion/VBoxLinuxAdditions.run"
else
  vBoxVersion=$(ls -d /opt/VBox*)
  if [[ $vBoxVersion != "" ]]; then
    sudo $vBoxVersion/init/vboxadd setup
  fi  
fi

echo -en "\e[7;40;37m\nChange /data ownership      \e[0m\n"
# if /data exist
if [[ -d /data ]]; then
  sudo chown -R $USER:$USER /data
fi

echo -en "\e[7;40;37m\nInstall NordVpn      \e[0m\n"
sudo apt install -y wget
sudo wget -qnc -P "$HOME/tmp" https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
sudo dpkg -i "$HOME/tmp/nordvpn-release_1.0.0_all.deb"
sudo apt update
sudo apt -y install nordvpn
nordvpn login
nordvpn whitelist add port 22
nordvpn whitelist add subnet 172.28.128.1/24
nordvpn set technology nordlynx
#nordvpn set cybersec on
#nordvpn set killswitch on
#nordvpn set autoconnect on
#nordvpn set obfuscate on
#nordvpn c

echo -en "\e[7;40;37m\nPackage updates             \e[0m\n"
sudo dpkg --configure -a
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade
# sudo apt -y clean
sudo apt -y autoremove
echo -en "\e[7;40;37m\nUpdate VBox Additions      \e[0m\n"
sudo /opt/VBoxGuestAdditions*/init/vboxadd setup

# echo -en "\e[7;40;37mRsync packages to host      \e[0m\n"
# rsync -axP --exclude="lock" --exclude="partial" /var/cache/apt/archives/ juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/archives/

echo -en "\e[7;40;37m\nClean and Empty disk        \e[0m\n"
sudo apt -y clean
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY

# Shutdown the machine
# sudo shutdown -h now

echo -en "\e[7;40;37m\nManual changes              \e[0m\n"
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