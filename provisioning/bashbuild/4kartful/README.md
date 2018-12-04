# kartful 4

2018-02-09

Kubuntu Artful vagrant virtual machine.
07 Install - working

## Installed

List of installations done:
1. Buildman
   1. 7 VirtualBox install

### Installing

```
# vagrant ssh -c "/srv/share/build/buildman.sh"
# vagrant ssh -c "tail -f buildmandebug.log"
```
Final update and upgrade
```
# vagrant ssh -c "sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y full-upgrade && sudo apt install -yf"
```
