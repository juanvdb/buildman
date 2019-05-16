#! /bin/bash

rsync -avxP --exclude="lock" --exclude="partial" /var/cache/apt/archives/ juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/archives/
rsync -avxP --exclude="lock" --exclude="partial" /var/cache/apt/lists/ juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/apt/lists/

# sudo rsync -avxP /var/lib/flatpak/repo/refs/remotes/ juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/flatpak/repo/refs/remotes/ 

sudo rsync -avxP /var/lib/snapd/snaps/ juan@172.28.128.1:/media/juan/xvms/cache/$(lsb_release -cs)/snapd/snaps/
