#!/bin/bash

vagrant halt
vagrant package --base $2 --output /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
vagrant destroy -f
vagrant box remove $1 -f
vagrant box add $1 /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
rm /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
rm -r $HOME/.vagrant.d/tmp/vagrant-package-*
