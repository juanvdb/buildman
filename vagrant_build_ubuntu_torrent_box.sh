#! /bin/bash
sudo usermod -aG nordvpn $USER
read -rp "Do you want to reboot (y/n)?" answer
if [[ $answer = [Yy1] ]]; then
  sudo reboot
fi
answer=NULL

sudo apt install -y wget qbittorrent
sudo wget -qnc -P "$HOME/tmp" https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
sudo dpkg -i "$HOME/tmp/nordvpn-release_1.0.0_all.deb"
sudo apt update
sudo apt -y install nordvpn
nordvpn login
nordvpn whitelist add port 22
nordvpn whitelist add subnet 172.28.128.1/24
nordvpn set technology nordlynx
nordvpn set cybersec on
nordvpn set killswitch on
nordvpn set autoconnect on
# nordvpn set obfuscate on
nordvpn c
sudo apt install -y openvpn network-manager-openvpn ca-certificates
nowpath=$(pwd)
cd /etc/openvpn || exit
sudo wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
sudo unzip -q ovpn.zip
sudo rm ovpn.zip
cd "$nowpath" || exit
sudo service network-manager restart
