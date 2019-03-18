#! /bin/bash

echo -en "\e[7;40;93m dpkg fix broken                                      \e[0m\n"
sudo dpkg --configure -a
echo -en "\e[7;40;93m apt fix broken                                       \e[0m\n"
sudo apt update && sudo apt --fix-broken install
echo -en "\e[7;40;93m update                                               \e[0m\n"
sudo apt update
echo -en "\e[7;40;93m upgrade                                              \e[0m\n"
sudo apt -y upgrade
echo -en "\e[7;40;93m dist upgrade                                         \e[0m\n"
sudo apt -y dist-upgrade
echo -en "\e[7;40;93m full upgrade                                         \e[0m\n"
sudo apt -y full-upgrade
# sudo apt -y clean
echo -en "\e[7;40;93m autoremove                                           \e[0m\n"
sudo apt -y autoremove
echo -en "\e[7;40;93m VBoxGuestAdditions                                   \e[0m\n"
sudo /opt/VBoxGuestAdditions*/init/vboxadd setup

echo -en "\e[7;40;93m rsync                                                \e[0m\n"
rsync -avxP --exclude="lock" --exclude="partial" /var/cache/apt/archives/ juan@172.28.128.1:/data/Backups/vagrantcache/$(lsb_release -cs)/apt/archives/

echo -en "\e[7;40;93m clean                                                \e[0m\n"
sudo apt -y clean

echo -en "\e[7;40;93m Start EMPTY                                          \e[0m\n"
sudo dd if=/dev/zero of=/EMPTY bs=1M
echo -en "\e[7;40;93m Remove EMPTY                                         \e[0m\n"
sudo rm -f /EMPTY

# Shutdown the machine
# sudo shutdown -h now
