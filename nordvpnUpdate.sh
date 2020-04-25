#! /bin/bash


nowpath=$(pwd)
[[ -d /etc/openvpn ]] || mkdir -p /etc/openvpn
cd /etc/openvpn || exit
sudo wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
sudo unzip -oq ovpn.zip
sudo rm ovpn.zip
cd "$nowpath" || exit
