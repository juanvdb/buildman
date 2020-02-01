#! /bin/bash

ip a
sudo apt install wget qbittorrent
sudo wget -qnc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
sudo dpkg -i nordvpn-release_1.0.0_all.deb
sudo apt update
sudo apt -y install nordvpn
nordvpn login -h
nordvpn login -u ***REMOVED*** -p ***REMOVED***
nordvpn c
nordvpn set cybersec on
nordvpn set killswitch on
nordvpn set autoconnect on
nordvpn set obfuscate on
nordvpn c
nordvpn settings
nordvpn status
nordvpn whitelist add subnet 172.28.128.1/24
nordvpn whitelist add port 22
nordvpn whitelist add port 111
nordvpn whitelist add port 2049
sudo apt install -y openvpn network-manager-openvpn ca-certificates
ls /etc/openvpn/
echo 'rsync -avxP The\ Lighthouse\ \(2019\)\ \[BluRay\]\ \[1080p\]\ \[YTS.LT\]/ juan@172.28.128.1:/media/juan/xvms/Movies/'
less ~/ytsuser.txt
./vagrant_ubuntu_upgrade_and_clean.sh
echo 'rsync -avxP --exclude="temp" ~/Downloads/ juan@172.28.128.1:/media/juan/xvms/Movies/'
