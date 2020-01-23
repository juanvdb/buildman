#! /bin/bash
sudo apt install -y wget qbittorrent
sudo wget -qnc -P "$HOME/tmp" https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
sudo dpkg -iy "$HOME/tmp/nordvpn-release_1.0.0_all.deb"
sudo apt update
sudo apt -y install nordvpn
nordvpn login -u '***REMOVED***' -p '***REMOVED***'
nordvpn whitelist add port 22
nordvpn whitelist add subnet 172.28.128.1/24
nordvpn set cybersec on
nordvpn set killswitch on
nordvpn set autoconnect on
nordvpn set obfuscate on
nordvpn c
sudo apt install -y openvpn network-manager-openvpn ca-certificates
nowpath=$(pwd)
cd /etc/openvpn || exit
sudo wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
sudo unzip ovpn.zip
sudo rm ovpn.zip
cd "$nowpath" || exit
sudo service network-manager restart
echo -e "***REMOVED***\\n***REMOVED***\\nhttps://yts.lt/\\nhttps://eztv.io/\\nhttps://extratorrent.ag/" | tee ~/ytsUser.txt
tee -a ~/ytsUser.txt << END
***REMOVED***
***REMOVED***
https://yts.lt/
https://eztv.io/
https://extratorrent.ag/
END
