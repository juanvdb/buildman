#! /bin/bash

sudo usermod -a -G vboxsf "$USER"
ip a
sudo apt install -y wget qbittorrent openvpn network-manager-openvpn ca-certificates
sudo wget -qnc -P "$HOME/tmp" https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
sudo dpkg -i "$HOME/tmp/nordvpn-release_1.0.0_all.deb"
sudo apt update
sudo apt -y install nordvpn
nordvpn login -h
nordvpn login -u ***REMOVED*** -p ***REMOVED***
nordvpn d
nordvpn set cybersec on
nordvpn set killswitch on
nordvpn set autoconnect of
nordvpn set obfuscate on
nordvpn c
nordvpn settings
nordvpn status
nordvpn d
nordvpn whitelist add subnet 172.28.128.1/24
nordvpn whitelist add port 22
nordvpn whitelist add port 111
nordvpn whitelist add port 2049
nordvpn c
read -rp "$1 Press ENTER to continue." nullEntry
printf "%s" "$nullEntry"
nordvpn d
# ls /etc/openvpn/
echo 'rsync -avxP The\ Lighthouse\ \(2019\)\ \[BluRay\]\ \[1080p\]\ \[YTS.LT\]/ juan@172.28.128.1:/media/juan/xvms/Movies/'
cp /srv/share/build/ytsuser.txt ~/
# less ~/ytsuser.txt
./vagrant_ubuntu_upgrade_and_clean.sh
echo 'rsync -avxP --exclude="temp" ~/Downloads/ juan@172.28.128.1:/media/juan/xvms/Movies/'
