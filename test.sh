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

function mainMenu() {
  local choiceOpt
  until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
    clear
    printf "

    There are the following options for this script
    TASK: DESCRIPTION
    ----: ---------------------------------------
    1   : Select and then auto run
    2   : Select and run step by step
    3   : Select from menu and run
    4   : Autorun one and two
    5   : Select one and three, then autorun
    6   : Select two and three, then step through
    0/q : Quit this program

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
        selection=(1 2)
        menuRun "AutoRun" "${selection[@]}"
      ;;
      5|five )
        selection=(1 3)
        menuRun "SelectThenAutoRun" "${selection[@]}"
      ;;
      6|six )
        selection=(2 3)
        menuRun "SelectThenStepRun" "${selection[@]}"
      ;;
    esac
  done
}

function menuRun() {
  local choiceOpt
  local typeOfRun=$1
  shift
  local menuSelections=($@)

  function selectionMenu (){
    local blue=$(tput setaf 4)
    local normal=$(tput sgr0)
    local bold=$(tput bold)
    local white=$(tput setaf 7)
    local yellow=$(tput setaf 3)
    local rev=$(tput rev)


    clear
    printf "\n\n"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "${rev}${bold}  Select items and then install the items without prompting.${normal}\n"
      ;;
      SelectThenStepRun )
        printf "${rev}${bold}  Select items and then install the items each with a prompt.${normal}\n"
      ;;
      SelectItem )
        printf "${rev}${bold}  Select items and for individual installation with prompt.${normal}\n"
      ;;
    esac
    printf "
    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "1" ]]; then printf "${rev}${bold}1${normal}"; else printf "1"; fi; printf "   : One\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "2" ]]; then printf "${rev}${bold}2${normal}"; else printf "2"; fi; printf "   : Two\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "3" ]]; then printf "${rev}${bold}3${normal}"; else printf "3"; fi; printf "   : Three\n"
    printf "\n"
    printf "     ${bold}9   : RUN${normal}\n"
    printf "\n"
    printf "    0/q  : Return to main menu\n\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\n\n"
    fi
  }

  function howToRun() {
    if [[ ! $2 = "SelectItem" ]]; then
      menuSelections+=("$1")
    else
      noPrompt=0
      runSelection "$1"
    fi
  }

  case $typeOfRun in
    AutoRun )
      noPrompt=1
      for i in "${menuSelections[@]}"; do
        runSelection "$i"
      done
      noPrompt=0
      menuSelections=()
      pressEnterToContinue
      return 0
    ;;
  esac

  until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
    selectionMenu "$typeOfRun"
    read -rp "Enter your choice : " choiceOpt
    case $choiceOpt in
      1|one )
        howToRun "1" "$typeOfRun"
      ;;
      2|two )
        howToRun "2" "$typeOfRun"
      ;;
      3|three )
        howToRun "3" "$typeOfRun"
      ;;
      9|RUN )
        if [[ $typeOfRun = "SelectThenAutoRun" ]]; then
          noPrompt=1
        fi
        for i in "${menuSelections[@]}"; do
          runSelection "$i"
        done
        noPrompt=0
        menuSelections=()
        pressEnterToContinue
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
