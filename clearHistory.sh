#! /bin/bash

if [[ -z $1 ]] || [[ -z $2 ]]; then
  echo "clearHistory <startline> <endline>"
  echo "Enter the start and end lines to be deleted"
  exit 1
fi

for (( i = $1; i <= $2; i++ )); do
  echo "From line $1 to line $2 deleting line $i"
  history | head -n $1 | tail -n 1
  history -d "$1"
done

for (( i = <start> ; i <= <end>; i++ )); do history -d <start>; done;
