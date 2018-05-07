# kartful 1

2018-01-31

Kubuntu Artful vagrant virtual machine.
Base with kernel updates, KDE Backports and KDE Updates.

To be used to install and test additional packages listed in the evernote install doc

## Installed

List of installations done:
1. Buildman
   1. run full Update 99 for Virtualbox

### Installing

```
# vagrant ssh -c "/srv/share/build/buildman.sh"
# vagrant ssh -c "tail -f buildmandebug.log"
```
Final update and upgrade
```
# vagrant ssh -c "sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y full-upgrade && sudo apt install -yf"
```
