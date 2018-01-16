#! /bin/bash

# rsync -avxP --exclude=lock --exclude=partial /home/juan/.vagrant.d/cache/kartful/apt/ /var/cache/apt/archives/
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade
# rsync -avxP --exclude=lock --exclude=partial /var/cache/apt/archives/ /home/juan/.vagrant.d/cache/kartful/apt/
sudo apt -y autoremove
# sudo apt -y clean
sudo flatpak update
sudo snap refresh
