#!/bin/bash

if [[ -z "${1// }" ]] || [[ -z "${2// }" ]]; then
  echo "No Parameters:"
  echo "Usage reBuildVagrantImage.sh <Vagrant Box name> <Virtual Box VM name>"
  exit 1
fi
echo -en "\e[7;49;96m Vagrant Halt                                        \e[0m\n"
vagrant halt
rm /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
echo -en "\e[7;49;96m Vagrant Package Base Box                            \e[0m\n"
vagrant package --base $2 --output /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
echo -en "\e[7;49;96m Vagrant Destroy Box                                 \e[0m\n"
vagrant destroy -f
vagrant box remove $1 -f
echo -en "\e[7;49;96m Vagrant Add Box                                     \e[0m\n"
vagrant box add $1 /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
echo -en "\e[7;49;96m Cleanup                                             \e[0m\n"
rm /home/juan/VirtualMachines/xVirtualMachines/VirtualBox/vagrantboxes/package.box
rm -r $HOME/.vagrant.d/tmp/vagrant-package-*
