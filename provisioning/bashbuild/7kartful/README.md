# kartful 7

Kubuntu Artful vagrant virtual machine.
Base with kernel updates, KDE Backports and KDE Updates.

## Installed

List of installations done:
1. Buildman
   1. Kernel Update
   2. KDE Updates
   3. Update, disk update and full update

### Installing

```
# vagrant ssh -c "/srv/share/buildman/buildman.sh"
# vagrant ssh -c "tail -f buildmandebug.log"
```
Final update and upgrade
```
# vagrant ssh -c "sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y full-upgrade && sudo apt install -yf"
```
