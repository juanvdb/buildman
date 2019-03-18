#! /bin/bash

rsync -avxP --exclude="lock" --exclude="partial" /var/cache/apt/archives/ juan@172.28.128.1:/data/Backups/vagrantcache/$(lsb_release -cs)/apt/archives/

rsync -avxP juan@172.28.128.1:/data/Backups/vagrantcache/$(lsb_release -cs)/flatpak/repo/refs/remotes/ /var/lib/flatpak/repo/refs/remotes/

rsync -avxP /var/lib/snapd/snaps/ juan@172.28.128.1:/data/Backups/vagrantcache/$(lsb_release -cs)/snapd/snaps/
