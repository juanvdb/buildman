#! /bin/bash

noPrompt=0

function asking() {
  if [[ $noPrompt -ne 1 ]]; then
    read -rp "Do you want to $1? (y/n)" answer
    if [[ $answer = [Yy1] ]]; then
      $2
      pressEnterToContinue "$1"
    fi
  else
    $2
  fi
}

pressEnterToContinue() {
  if [[ $noPrompt -ne 1 ]]; then
    read -rp "$1 Press ENTER to continue." nullEntry
    printf "%s" "$nullEntry"
  fi
}

function menuRun() {
  until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
    clear
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------
    1    : One
    2    : Two
    3    : Three

    0/q  : Quit this program

    "

    read -rp "Enter your choice : " choiceOpt
    runSelection $choiceOpt
  done
}

function runSelection() {
  # take inputs and perform as necessary
  case $1 in
    1|one )
      asking "run function one" functionOne
    ;;
    2|two )
      asking "run function two" functionTwo
    ;;
    3|three )
      asking "run function three" functionThree
    ;;
  esac
}

function optionInstall() {
  echo "Running from optionInstall functiom"
}

function functionOne() {
  echo "Running functionOne"
}

function functionTwo() {
  echo "Running functionTwo"
}

function functionThree() {
  echo "Running functionThree"
}

menuRun

asking "asking to run the optionInstall function" optionInstall

firstSteps=(one two three)
lastSteps=(three two one)

for i in "${firstSteps[@]}"; do
  runSelection "$i"
done

for i in "${lastSteps[@]}"; do
  noPrompt=1
  runSelection "$i"
  pressEnterToContinue "Finished lastSteps"
done


exit 0
