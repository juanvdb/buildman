#! /bin/bash
# Setup of a Virtualbox machine

sudo usermod -G vboxsf -a $USER
sudo chown -R root:vboxsf /srv/host
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
echo -en "\e[7;40;93m dpkg fix broken                                      \e[0m\n"
sudo dpkg --configure -a
echo -en "\e[7;40;93m apt fix broken                                       \e[0m\n"
sudo apt -y --fix-broken instal
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade
# rsync -avxP --exclude=lock --exclude=partial /var/cache/apt/archives/ /home/juan/.vagrant.d/cache/kartful/apt/
sudo apt -y autoremove
# sudo apt -y clean
sudo flatpak update
sudo snap refresh

sudo dpkg --configure -a && sudo apt -y install --fix-broken && sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y full-upgrade && sudo apt -y autoremove && sudo apt -y clean
