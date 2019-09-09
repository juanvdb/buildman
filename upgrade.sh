#! /bin/bash

release=$(lsb_release -cs)
echo -en "\e[7;40;93mFull KDE $release system upgrade                        \e[0m\n\n"

# pkcon refresh
# pkcon -y update
# echo -en "\e[7;40;93mGem Update                                        \e[0m\n"
# sudo gem update
echo -en "\e[7;40;93mApt Update                                                                        \e[0m\n"
sudo apt update
echo -en "\e[7;40;93mApt Upgrade                                                                       \e[0m\n"
sudo apt -y upgrade
echo -en "\e[7;40;93mApt Dist Ugrade                                                                   \e[0m\n"
sudo apt -y dist-upgrade
echo -en "\e[7;40;93mApt Full Upgrade                                                                  \e[0m\n"
sudo apt -y full-upgrade
echo -en "\e[7;40;93mFlatpak Update                                                                    \e[0m\n"
sudo flatpak -y update
flatpak -y update
echo -en "\e[7;40;93mSnap Update                                                                       \e[0m\n"
sudo snap refresh
if [ -d "/media/juan/xvms/cache" ]; then
  echo -en "\e[7;40;93mRsync to Vagrant Cache in Backups                                                                 \e[0m\n"
  # release=$(lsb_release -cs)
  rsync -avx --exclude="lock" --exclude="partial" /var/cache/apt/archives/ /media/juan/xvms/cache/$(lsb_release -cs)/apt/archives/
  rsync -avx --exclude="lock" --exclude="partial" /var/lib/apt/lists/ /media/juan/xvms/cache/$(lsb_release -cs)/apt/lists/
  rsync -avx /var/lib/flatpak/repo/refs/remotes/ /media/juan/xvms/cache/$(lsb_release -cs)/flatpak/repo/refs/remotes/
  sudo rsync -avx /var/lib/snapd/snaps/ /media/juan/xvms/cache/$(lsb_release -cs)/snapd/snaps
  sudo chown -R juan:juan /media/juan/xvms/cache/
fi
echo -en "\e[7;40;93mApt Autoremove                                                                    \e[0m\n"
sudo apt -y autoremove
echo -en "\e[7;40;93mApt Clean                                                                         \e[0m\n"
sudo apt -y clean
# snap refresh --beta --devmode anbox
