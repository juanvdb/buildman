# kartful 3

2018-02-10

Testing installs that fail NFS link after install...

Kubuntu Artful vagrant virtual machine.
Build install 99 test - Working

## Installed

List of installations done:
1. Buildman
  1. 99 install

### Installing

```
# vagrant ssh -c "/srv/share/build/buildman.sh"
# vagrant ssh -c "tail -f buildmandebug.log"
```
Final update and upgrade
```
# vagrant ssh -c "sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y full-upgrade && sudo apt install -yf"
```
