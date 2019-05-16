#! /bin/bash

sudo rsync -avxP --exclude="lock" --exclude="partial" juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/archives/ /var/cache/apt/archives/
sudo rsync -avxP --exclude="lock" --exclude="partial" juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/lists/ /var/cache/apt/lists/

# sudo rsync -avxP juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/flatpak/repo/refs/remotes/ /var/lib/flatpak/repo/refs/remotes/

sudo rsync -avxP juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/snapd/snaps/ /var/lib/snapd/snaps/
