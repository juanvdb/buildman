#! /bin/bash

currentpath=$(pwd)
sudo chown -R "$USER:$USER" /data
cd /data || exit
mkdir -p /data/bin
mkdir -p /data/Documents
mkdir -p /data/Downloads
mkdir -p /data/Music
mkdir -p /data/Pictures
mkdir -p /data/Videos
mkdir -p /data/ownCloud
mkdir -p /data/VirtualMachines
mkdir -p /data/Dropbox
mkdir -p /data/GoogleDrive
mkdir -p /data/SpiderOak\ Hive
mkdir -p /data/Software
mkdir -p /data/.thunderbird
mkdir -p /data/.cxoffice
mkdir -p /data/.atom
mkdir -p /data/.nylas
mkdir -p /data/scripts
mkdir -p /data/vagrant
mkdir -p /data/.vagrant.d
cd "$currentpath" || exit
