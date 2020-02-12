#! /bin/bash
# Setup of a Virtualbox machine

sudo usermod -G vboxsf -a $USER
sudo chown -R root:vboxsf /srv/host
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
