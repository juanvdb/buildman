#! /bin/bash

ipaddress=(10.150.247.162
10.150.247.162
10.148.14.222
10.150.244.75
10.148.41.21
10.148.48.232
10.148.48.232
10.227.170.37
10.227.170.38
10.227.170.40
10.227.170.41
10.227.169.70
10.127.169.71
redhat.com
docker.io
docker.com
openshift.io
openshift.org
docker.io
docker.org
fabric8.io
jboss.org
jenkins-ci.org
jenkins.io
bitbucket.org
github.com
redhat.com
docker.io
docker.com
openshift.io
openshift.org
docker.io
docker.org
fabric8.io
jboss.org
jenkins-ci.org
jenkins.io
bitbucket.org
github.com)

port=(6553
7782
443
5019
22
29999
9980
22
22
22
22
9002
9002
443
443
443
443
443
443
443
443
443
443
443
443
443
80
80
80
80
80
80
80
80
80
80
80
80
80)

echo "${#ipaddress[@]}"
for (( i = 0; i < ${#ipaddress[@]}; i++ )); do
  printf "IP Address: %s:%s\n" "${ipaddress[$i]}" "${port[$i]}"
  nc -tvi 1 "${ipaddress[$i]}" "${port[$i]}"
done
read -rp "$1 Press ENTER to continue." nullEntry
printf "%s" "$nullEntry\n"

  for (( i = 8100; i < 8399; i++ )); do nc -tvi 1 10.227.170.37 "$i"; done;
  read -rp "$1 Press ENTER to continue." nullEntry
  for (( i = 8100; i < 8399; i++ )); do nc -tvi 1 10.227.170.38 "$i"; done;
  read -rp "$1 Press ENTER to continue." nullEntry
  for (( i = 8100; i < 8399; i++ )); do nc -tvi 1 10.227.170.40 "$i"; done;
  read -rp "$1 Press ENTER to continue." nullEntry
  for (( i = 8100; i < 8399; i++ )); do nc -tvi 1 10.227.170.41 "$i"; done;
