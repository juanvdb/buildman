#!/bin/bash

if [[ -z "${1// }" ]] || [[ -z "${2// }" ]]; then
  echo "No Parameters:"
  echo "Usage reBuildVagrantImage.sh <Vagrant Box name> <Virtual Box VM name>"
  exit 1
fi
vagrant halt
rm /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
vagrant package --base $2 --output /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
vagrant destroy -f
vagrant box remove $1 -f 
vagrant box add $1 /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box 
rm /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
rm -r $HOME/.vagrant.d/tmp/vagrant-package-*
