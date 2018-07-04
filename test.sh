#! /bin/bash

noPrompt=0

function asking() { #$1 function to call, $2 Question to ask, $3 Finished message
  if [[ $noPrompt -eq 0 ]]; then
    read -rp "Do you want to $2? (y/n)" answer
    if [[ $answer = [Yy1] ]]; then
      $1
      pressEnterToContinue "$3"
    fi
  else
    $1
  fi
}

pressEnterToContinue() {
  if [[ $noPrompt -eq 0 ]]; then
    read -rp "$1 Press ENTER to continue." nullEntry
    printf "%s" "$nullEntry"
  fi
}

function menuRun() {
  local choiceOpt
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

function mainMenu() {
  local choiceOpt
  until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
    clear
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------
    1    : Select and then auto run
    2    : Select and run step by step
    3    : Select from menu and run

    0/q  : Quit this program

    "

    read -rp "Enter your choice : " choiceOpt
    case $choiceOpt in
      1|one )
        menuRun "SelectThenAutoRun"
      ;;
      2|two )
        menuRun "SelectThenStepRun"
      ;;
      3|three )
        menuRun "SelectItem"
      ;;
      4|four )
        menuRun "AutoRun"
      ;;
    esac
  done
}

function runSelection() {
  # take inputs and perform as necessary
  case $1 in
    1|one )
      asking functionOne "run function one" "Function One Complete"
    ;;
    2|two )
      asking functionTwo "run Function Two" "Function Two Complete"
    ;;
    3|three )
      asking functionThree "run Function Three" "Function Three Complete"
    ;;
  esac
}

function stepRun() {
  local stepSelection=()

  function askSteprun() {
    read -rp "Do you want to run $1? (y/n)" answer
    if [[ $answer = [Yy1] ]]; then
      stepSelection+=($2)
    fi
  }
  askSteprun "one" "one"
  askSteprun "two" "two"
  askSteprun "three" "three"
  noPrompt=1
  for i in "${stepSelection[@]}"; do
    runSelection "$i"
  done
  noPrompt=0
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

mainMenu

exit 0
