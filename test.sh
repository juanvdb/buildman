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

  # local blue
  # blue=$(tput setaf 4)
  # local white
  # white=$(tput setaf 7)
  local yellow
  yellow=$(tput setaf 3)
  local normal
  normal=$(tput sgr0)
  local bold
  bold=$(tput bold)
  local rev
  rev=$(tput rev)

  function selectionMenu (){

    clear
    printf "\n\n"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  %s%sSelect items and then install the items without prompting.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
      SelectThenStepRun )
        printf "  %s%sSelect items and then install the items each with a prompt.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
      SelectItem )
        printf "  %s%sSelect items and for individual installation with prompt.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
    esac
    printf "
    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "1" ]]; then printf "%s%s1%s" "${rev}" "${bold}" "${normal}"; else printf "1"; fi; printf "   : One\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "2" ]]; then printf "%s%s2%s" "${rev}" "${bold}" "${normal}"; else printf "2"; fi; printf "   : Two\n"
    printf "\n"
    printf "     a   : Sub Menu A\n"
    printf "     b   : Sub Menu B\n"
    printf "\n"
    printf "     %s9   : RUN%s\n" "${bold}" "${normal}"
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

  function submenuA (){
    clear
    printf "\n\n"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  %s%sSelect items and then install the items without prompting.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
      SelectThenStepRun )
        printf "  %s%sSelect items and then install the items each with a prompt.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
      SelectItem )
        printf "  %s%sSelect items and for individual installation with prompt.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
    esac
    printf "
    %sOptions 3 and 4%s

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n" "${yellow}" "${normal}"
    printf "     ";if [[ "${menuSelections[*]}" =~ "3" ]]; then printf "%s%s3%s" "${rev}" "${bold}" "${normal}"; else printf "3"; fi; printf "   : Three\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "4" ]]; then printf "%s%s4%s" "${rev}" "${bold}" "${normal}"; else printf "4"; fi; printf "   : Four\n"
    printf "\n"
    printf "    0/q  : Return to Selection menu\n\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\n\n"
    fi
  }

  function submenuB (){
    clear
    printf "\n\n"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  %s%sSelect items and then install the items without prompting.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
      SelectThenStepRun )
        printf "  %s%sSelect items and then install the items each with a prompt.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
      SelectItem )
        printf "  %s%sSelect items and for individual installation with prompt.%s\n" "${rev}" "${bold}" "${normal}"
      ;;
    esac
    printf "
    %sOptions 5 and 6%s

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n" "${yellow}" "${normal}"
    printf "     ";if [[ "${menuSelections[*]}" =~ "5" ]]; then printf "%s%s5%s" "${rev}" "${bold}" "${normal}"; else printf "5"; fi; printf "   : Five\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "6" ]]; then printf "%s%s6%s" "${rev}" "${bold}" "${normal}"; else printf "6"; fi; printf "   : Six\n"
    printf "\n"
    printf "    0/q  : Return to Selection menu\n\n"

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
    if ((1<=choiceOpt && choiceOpt<=2))
    then
      howToRun "$choiceOpt" "$typeOfRun"
    elif ((3<=choiceOpt && choiceOpt<=4))
    then
      howToRun "$choiceOpt" "$typeOfRun"
    elif ((5<=choiceOpt && choiceOpt<=6))
    then
      howToRun "$choiceOpt" "$typeOfRun"
    elif ((choiceOpt==99))
    then
      if [[ $typeOfRun = "SelectThenAutoRun" ]]; then
        noPrompt=1
      fi
      for i in "${menuSelections[@]}"; do
        runSelection "$i"
      done
      noPrompt=0
      menuSelections=()
      pressEnterToContinue
    else
      case $choiceOpt in
        a )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuA "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            if ((3<=choiceOpt && choiceOpt<=4))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            # elif ((3<=choiceOpt && choiceOpt<=4))
            # then
            #   howToRun "$choiceOpt" "$typeOfRun"
            # elif ((5<=choiceOpt && choiceOpt<=6))
            # then
            #   howToRun "$choiceOpt" "$typeOfRun"
            # elif ((choiceOpt==99))
            # then
            #   if [[ $typeOfRun = "SelectThenAutoRun" ]]; then
            #     noPrompt=1
            #   fi
            #   for i in "${menuSelections[@]}"; do
            #     runSelection "$i"
            #   done
            #   noPrompt=0
            #   menuSelections=()
            #   pressEnterToContinue
            fi
          done
          choiceOpt=NULL
        ;;
        b )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuB "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            if ((5<=choiceOpt && choiceOpt<=6))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            # elif ((3<=choiceOpt && choiceOpt<=4))
            # then
            #   howToRun "$choiceOpt" "$typeOfRun"
            # elif ((5<=choiceOpt && choiceOpt<=6))
            # then
            #   howToRun "$choiceOpt" "$typeOfRun"
            # elif ((choiceOpt==99))
            # then
            #   if [[ $typeOfRun = "SelectThenAutoRun" ]]; then
            #     noPrompt=1
            #   fi
            #   for i in "${menuSelections[@]}"; do
            #     runSelection "$i"
            #   done
            #   noPrompt=0
            #   menuSelections=()
            #   pressEnterToContinue
            fi
          done
          choiceOpt=NULL
        ;;
      esac
    fi
    # case $choiceOpt in
    #   [1-8] )
    #     howToRun "$choiceOpt" "$typeOfRun"
    #   ;;
    #   # 2|two )
    #   #   howToRun "2" "$typeOfRun"
    #   # ;;
    #   # 3|three )
    #   #   howToRun "3" "$typeOfRun"
    #   # ;;
    #   9|RUN )
    #     if [[ $typeOfRun = "SelectThenAutoRun" ]]; then
    #       noPrompt=1
    #     fi
    #     for i in "${menuSelections[@]}"; do
    #       runSelection "$i"
    #     done
    #     noPrompt=0
    #     menuSelections=()
    #     pressEnterToContinue
    #   ;;
    # esac
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
