#!/bin/bash

# DateVer 2020/02/10
# Buildman
buildmanVersion=V4.6.3
# Author : Juan van der Breggen

# Tools used/required for implementation : bash, sed, grep, regex support, gsettings, apt
# and of-course privilege for setting up apt.
# The user should be in the sudoers to set up apt, or modify the script as required.
#
# This script builds a new system from the Debian family.
# Configures apt, repos, environment variables and gsettings, install new applications
#
# Check the following releases before proceding
# - DisplayLink
# - ddd-3
#
# So, lets proceed.
# version="0.12";
# ############################################################################
# To do
# Ask questions for specific packages
# Add option for Virtual Box
# Add following packages
# from evernote notes
# crossover

# ############################################################################
# ==> set global Variables

# Global Variables
{
  betaReleaseName="focal"
  betaReleaseVer="20.04"
  stableReleaseName="eoan"
  stableReleaseVer="19.10"
  previousStableReleaseName="disco"
  previousStableReleaseVer="19.04"
  noCurrentReleaseRepo=0
  betaAns=0

  ltsReleaseName="bionic"
  desktopEnvironment=""
  kernelRelease=$(uname -r)
  distReleaseVer=$(lsb_release -sr)
  distReleaseName=$(lsb_release -sc)
  noPrompt=0

  mkdir -p "$HOME/tmp"
  sudo chown "$USER":"$USER" "$HOME/tmp"
  debugLogFile="$HOME/tmp/buildman.log"
  errorLogFile="$HOME/tmp/buildman_error.log"

  # black=$(tput setaf 0)
  red=$(tput setaf 1)
  green=$(tput setaf 2)
  yellow=$(tput setaf 3)
  # blue=$(tput setaf 4)
  # magenta=$(tput setaf 5)
  # cyan=$(tput setaf 6)
  # white=$(tput setaf 7)
  normal=$(tput sgr0)
  bold=$(tput bold)
  rev=$(tput rev)
}
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                          Debug                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

#--------------------------------------------------------------------------------------------------
# ############################################################################
# ==> set debugging on
# echo "Press CTRL+C to proceed."
# trap "pkill -f 'sleep 1h'" INT
# trap "set +xv ; sleep 1h ; set -xv" DEBUG
# set -e  # Fail on first error


# source /home/juanb/ownCloud/bashscripts/log4bash-master/log4bash.sh
# source /home/juan/data/ownCloud/bashscripts/log4bash-master/log4bash.sh

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
INTERACTIVE_MODE="on"
scriptDebugToStdout="off"
scriptDebugToFile="on"
switchPrintln="on"
if [[ $scriptDebugToFile == "on" ]]; then
  if [[ -e $debugLogFile ]]; then
    # >$debugLogFile
    echo -en "\\n \033[1;31m   ##############################################################\\n\033[0m
    \\n
    \033[1;31m START OF NEW RUN\\n\033[0m
    \\n
    \033[1;31m###############################################################\\n\033[0m\\n" >>"$debugLogFile"
  else
    touch "$debugLogFile"
  fi
  if [[ -e $errorLogFile ]]; then
    echo -en "\\n \033[1;31m##############################################################\\n\033[0m
    \\n
    \033[1;31m START OF NEW RUN\\n\033[0m
    \\n
    \033[1;31m###############################################################\\n\033[0m\\n" >>"$errorLogFile"
    echo -en "\\n" >>"$errorLogFile"
  else
    touch "$errorLogFile"
  fi
fi

# ############################################################################
# debug function - replaced by log4bash
debug () {
  #[[ $script_debug = 1 ]] && "$@" || :

  #printf "DEBUG: %s\\n" "$1"
  if [[ $scriptDebugToStdout == "on" ]]
  then
    printf "DEBUG: %q\\n" "$@"
  fi
  if [[ $scriptDebugToFile == "on" ]]
  then
    printf "DEBUG: %q\\n" "$@" >>"$debugLogFile" 2>>"$errorLogFile"
  fi
  # [[ $script_debug = 1 ]] && printf "DEBUG: %q\\n" "$@" >>$debugLogFile 2>>$errorLogFile || :
  #log "$@" >>$debugLogFile 2>>$errorLogFile
}

# ############################################################################
# log4bash
#--------------------------------------------------------------------------------------------------
# Begin Logging Section
if [[ "${INTERACTIVE_MODE}" == "off" ]]
then
    # Then we don't care about log colors
    declare -r LOG_DEFAULT_COLOR=""
    declare -r LOG_ERROR_COLOR=""
    declare -r LOG_INFO_COLOR=""
    declare -r LOG_SUCCESS_COLOR=""
    declare -r LOG_WARN_COLOR=""
    declare -r LOG_INFO_COLOR=""
    declare -r BANNER_BLUE=""
    declare -r BANNER_YELLOW=""
    declare -r LOG_BANNER_GREY=""
    declare -r LOG_BANNER_BLUE=""
    declare -r LOG_BANNER_YELLOW=""
else
    declare -r LOG_DEFAULT_COLOR="\033[0m"
    declare -r LOG_ERROR_COLOR="\033[1;31m"
    declare -r LOG_INFO_COLOR="\033[1m"
    declare -r LOG_SUCCESS_COLOR="\033[1;32m"
    declare -r LOG_WARN_COLOR="\033[1;33m"
    declare -r LOG_DEBUG_COLOR="\033[1;34m"
    declare -r BANNER_BLUE="\e[7;44;39m"
    declare -r BANNER_YELLOW="\e[0;103;30m"
    declare -r LOG_BANNER_GREY="\e[7;40;97m"
    declare -r LOG_BANNER_BLUE="\e[7;107;34m"
    declare -r LOG_BANNER_YELLOW="\e[0;103;30m"
fi

log() {
    local log_text="$1"
    local log_level="$2"
    local log_color="$3"

    # Default level to "info"
    [[ -z ${log_level} ]] && log_level="INFO";
    [[ -z ${log_color} ]] && log_color="${LOG_INFO_COLOR}";

    if [[ $scriptDebugToStdout == "on" ]]; then
      echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}";
    fi
    if [[ $scriptDebugToFile == "on" ]]
    then
      echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}" >>"$debugLogFile" 2>>"$errorLogFile"
    fi
    # [[ $script_debug = 1 ]] && echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}" >>$debugLogFile 2>>$errorLogFile || :
    return 0;
}

log_info()      { log "$@"; }
log_success()   { log "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
log_error()     { log "$1" "ERROR" "${LOG_ERROR_COLOR}"; }
log_warning()   { log "$1" "WARNING" "${LOG_WARN_COLOR}"; }
log_debug()     { log "$1" "DEBUG" "${LOG_DEBUG_COLOR}"; }
log_info_banner()     { log "$1" "" "$LOG_BANNER_GREY"; }
log_debug_banner ()   { log "$1" "DEBUG" "${LOG_BANNER_BLUE}"; }
log_warning_banner () { log "$1" "WARNING" "${LOG_BANNER_YELLOW}"; }


println() {
  local println_text="$1"
  local println_color="$2"

  # Default level to "info"
  [[ -z ${println_color} ]] && println_color="${LOG_INFO_COLOR}";
  if [[ $switchPrintln == "on" ]]; then
    echo -e "${println_color} ${println_text} ${LOG_DEFAULT_COLOR}";
  fi
  return 0;
}

println_info()            { println "$@"; }
println_banner_yellow()   { println "$1" "${BANNER_YELLOW}"; }
println_banner_blue()     { println "$1" "${BANNER_BLUE}"; }
println_red()             { println "$1" "${LOG_ERROR_COLOR}"; }
println_yellow()          { println "$1" "${LOG_WARN_COLOR}"; }
println_blue()            { println "$1" "${LOG_DEBUG_COLOR}"; }


# ############################################################################
#--------------------------------------------------------------------------------------------------

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O       General system functions                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO


# ############################################################################
# Die process to exit because of a failure
die() { echo "$*" >&2; exit 1; }

# ############################################################################
# Halt flow if noPrompt is off (0) and ask that Enter is pressed to continue
pressEnterToContinue() {
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "$1 Press ENTER to continue." nullEntry
    printf "%s" "$nullEntry"
  fi
}

# ############################################################################
# Ask do you want to...(run the function) if noPrompt is off (0) and ask that Enter is pressed to continue
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

# ############################################################################
# Ask if you want to run the selection.
# Parameters: askDoYouWantTo functionToCall "text for the ask question" "text for the complete and press Enter"
function askDoYouWantTo() { #$1 function to call, $2 Question to ask, $3 Finished message
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


# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                   Check system                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

############################################################################
# Desktop environment check and return desktop environment
desktopEnvironmentCheck () {
  log_info "Desktop environment check"
  println_banner_yellow "Desktop environment check                                            "
  # another way for ssh terminals

  if [[ -z "$XDG_CURRENT_DESKTOP" ]];
  then
    # shellcheck disable=SC2001 disable=SC2143
    if [[ -z $(echo "$XDG_DATA_DIRS" | grep -Eo 'xfce|kde|gnome') ]]; then
      # desktop=$(pgrep -l "compiz|metacity|mutter|kwin|sawfish|fluxbox|openbox|xmonad")
      desktop=$(pgrep -l "gnome|kde|mate|cinnamon")
      case $desktop in
        *"startkde"* )
        desktop="kde"
        ;;
        *"gnome-shell"* )
        desktop="gnome"
        ;;
      esac
    else
      desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|plasma\|gnome\).*/\1/')
    fi
  else
    desktop=$XDG_CURRENT_DESKTOP
  fi
  # convert to lower case
  desktop=${desktop,,}

  # debug "desktopEnvironmentCheck -GDMSESSION = $GDMSESSION"
  case $desktop in
    "kde" | "plasma")
    desktopEnvironment="kde"
    ;;
    "gnome" )
    desktopEnvironment="gnome"
    ;;
    "xfce" )
    desktopEnvironment="xubuntu"
    ;;
    "ubuntu:GNOME" | "ubuntu:gnome")
    desktopEnvironment="ubuntu"
    ;;
    * )
    desktopEnvironment="kde"
    ;;
  esac
}

############################################################################
# Simple script to check for all PPAs refernced in your apt sources and
# to grab any signing keys you are missing from keyserver.ubuntu.com.
# Additionally copes with users on launchpad with multiple PPAs
# (e.g., ~asac)
#
# Author: Dominic Evans https://launchpad.net/~oldman
# License: LGPL v2
ppaKeyCheck () {
  println_banner_yellow "Repositories Key Check and Update                                    "

  for APT in `find /etc/apt/ -name *.list`; do
      grep -o "^deb http://ppa.launchpad.net/[a-z0-9\-]\+/[a-z0-9\-]\+" "$APT" | while read ENTRY ; do
          # work out the referenced user and their ppa
          USER=`echo $ENTRY | cut -d/ -f4`
          PPA=`echo $ENTRY | cut -d/ -f5`
          # some legacy PPAs say 'ubuntu' when they really mean 'ppa', fix that up
          if [ "ubuntu" = "$PPA" ]
          then
              PPA=ppa
          fi
          # scrape the ppa page to get the keyid
          KEYID=`wget -q --no-check-certificate https://launchpad.net/~$USER/+archive/$PPA -O- | grep -o "1024R/[A-Z0-9]\+" | cut -d/ -f2`
          sudo apt-key adv --list-keys "$KEYID" >/dev/null 2>&1
          if [ $? != 0 ]
          then
              echo "Grabbing key $KEYID for archive $PPA by ~$USER"
              sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com "$KEYID"
          else
              echo "Already have key $KEYID for archive $PPA by ~$USER"
          fi
      done
  done
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                  Update and upgrade                                      O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Update the repositories
# Update repositories - hopefully only need to call once
repoUpdate () {
  log_info "Repo Update"
  println_banner_yellow "Repo Update                                                          "
  sudo apt update -y;
}

# ############################################################################
# Upgrade the system
# Upgrade the system and distro  - hopefully only need to call once
repoUpgrade () {
  log_info "Repo Upgrade"
  println_banner_yellow "Repo Upgrade                                                         "
  sudo apt install -yf;
  sudo apt upgrade -y;
  sudo apt full-upgrade -y;
  sudo apt dist-upgrade -y;
  sudo apt autoremove -y;apt-get clean

  # sudo apt clean -y
}

repoCleanAll () {
  sudo apt-get clean -y
  sudo rm /var/lib/apt/lists/*
  sudo rm /var/lib/apt/lists/partial/*
  sudo apt-get clean -y
  sudo apt update
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                         Kernel                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Setup Kernel
kernelUprade () {
  log_info "Kernel Upgrade"
  println_banner_yellow "Kernel Upgrade                                                        "
  if [[ $noPrompt -eq 0 ]]; then
    read -rp "Do you want to go ahead with the kernel and packages Upgrade, and possibly will have to reboot (y/n)?" answer
  else
    answer=1
  fi
  if [[ $answer = [Yy1] ]]; then
    repoUpdate
    # sudo apt install -yf build-essential linux-headers-"$kernelRelease" linux-image-extra-"$kernelRelease" linux-signed-image-"$kernelRelease" linux-image-extra-virtual;
    sudo apt install -yf build-essential linux-headers-"$kernelRelease" linux-image-extra-virtual;
    sudo apt upgrade -y;
    sudo apt full-upgrade -y;
    sudo apt dist-upgrade -y;
    if [[ "$noPrompt" -ne 1 ]]; then
      read -rp "Do you want to reboot (y/n)?" answer
      if [[ $answer = [Yy1] ]]; then
        sudo reboot
      fi
    fi
  fi
  answer=NULL
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O              Virtual Machines Setup                                      O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# VMware Guest Setup, vmtools, nfs directories to host
vmwareGuestSetup () {
  log_info "VMware setup with Open VM Tools and NFS file share to host"
  println_blue "VMware setup with Open VM Tools and NFS file share to host           "
  sudo apt install -y nfs-common ssh open-vm-tools open-vm-tools-desktop
  mkdir -p "$HOME/hostfiles/home"
  mkdir -p "$HOME/hostfiles/data"
  LINE1="172.22.8.1:/home/juanb/      $HOME/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="172.22.8.1:/data      $HOME/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  LINE3="172.22.1.1:/home/juanb/      $HOME/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE3|h; \${x;s|$LINE3||;{g;t};a\\" -e "$LINE3" -e "}" /etc/fstab
  LINE4="172.22.1.1:/data      $HOME/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE4|h; \${x;s|$LINE4||;{g;t};a\\" -e "$LINE4" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" "$HOME/hostfiles"
  # sudo mount -a
}

# ############################################################################
# VirtualBox Host Setup
virtualboxHostInstall () {
  log_info "VirtualBox Host setup"
  println_blue "VirtualBox Host setup                                                         "

  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the VirtualBox repo? (y/n))" answer
    if [[ $answer = [yY1] ]]; then
      # Uncomment to add repository and get latest releases
      wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
      wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
      echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $distReleaseName contrib" | sudo tee "/etc/apt/sources.list.d/virtualbox-$distReleaseName.list"
      if [[ $betaAns == 1 ]]; then
        log_warning "Beta Code, revert the Virtualbox apt sources."
        println_red "Beta Code, revert the Virtaulbox apt sources."
        changeAptSource "/etc/apt/sources.list.d/virtualbox-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        # repoUpdate
      elif [[ $noCurrentReleaseRepo == 1 ]]; then
        log_warning "No new repo, revert the Virtualbox apt sources."
        println_red "No new repo, revert the Virtaulbox apt sources."
        changeAptSource "/etc/apt/sources.list.d/virtualbox-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
      fi
      repoUpdate
    fi
  fi
  sudo apt install -y virtualbox dkms virtualbox-ext-pack virtualbox-guest-additions-iso
}

# ############################################################################
# VirtualBox Guest Setup, vmtools, nfs directories to host
virtualboxGuestSetup () {
  log_info "VirtualBox setup NFS file share to hostfiles"
  println_blue "VirtualBox setup NFS file share to hostfiles                         "
  sudo apt install -y nfs-common ssh virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
  mkdir -p "$HOME/hostfiles/home"
  mkdir -p "$HOME/hostfiles/data"
  LINE1="192.168.56.1:/home/juanb/      $HOME/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="192.168.56.1:/data      $HOME/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" "$HOME/hostfiles"
  # sudo mount -a
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                     Home directory setup                                 O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Create directories on data disk for testing
createTestDataDirs () {
  log_info "Create Test Data directories"
  currentPath=$(pwd)
  cd "$HOME" || exit

  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    sudo chown -R "$USER:$USER" /data
    if [ -d "$HOME/$sourceDataDirectory" ]; then
      if [ -L "$HOME/$sourceDataDirectory" ]; then
        # It is a symlink!
        log_info "Keep symlink $HOME/data"
        # log_debug "Remove symlink $HOME/data"
        # rm "$HOME/$sourceDataDirectory"
        # ln -s "/data" "$HOME/$sourceDataDirectory"
      else
        # It's a directory!
        # log_debug "Remove directory $HOME/data"
        rm -R "${HOME}/${sourceDataDirectory}:?"
        ln -s "/data" "$HOME/$sourceDataDirectory"
      fi
    else
      # log_debug "Link directory $HOME/data"
      ln -s "/data" "$HOME/$sourceDataDirectory"
    fi

    linkDataDirectories=(
    "bin"
    "docker"
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Videos"
    "ownCloud"
    "VirtualMachines"
    "Dropbox"
    "GoogleDrive"
    "SpiderOak Hive"
    "Software"
    ".mozilla"
    ".thunderbird"
    ".cxoffice"
    ".atom"
    ".nylas"
    "scripts"
    "dev"
    )

    log_info "linkDataDirectories ${linkDataDirectories[*]}"

    for sourceLinkDirectory in "${linkDataDirectories[@]}"; do
      # log_debug "Link directory = $sourceLinkDirectory"
      mkdir -p "/data/$sourceLinkDirectory"
    done

    # Link DataDirectories from sub dirs to specified home dir
    linkDataDirectories=(
    "vagrant/vagrant" "vagrant"
    "vagrant/.vagrant.d" ".vagrant.d"
    )

    log_info "linkDataDirectories ${linkDataDirectories[*]}"
    count=$(((${#linkDataDirectories[@]}+1)/2))

    for (( i = 0; i <= count; i+=2 )); do
      sourceLinkDirectory=${linkDataDirectories[i]}
      targetLinkDirectory=${linkDataDirectories[i+1]}
      # log_debug "Link directory = $sourceLinkDirectory"
      # remove after testing
      mkdir -p "/data/$sourceLinkDirectory"
      # up to here
    done
  fi
}

# ############################################################################
# Links directories to data disk if exists
dataDirLinksSetup () {
  log_info "Data Dir links"
  currentPath=$(pwd)
  cd "$HOME" || exit

  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    if [ -d "$HOME/$sourceDataDirectory" ]; then
      if [ -L "$HOME/$sourceDataDirectory" ]; then
        # It is a symlink!
        log_debug "Keep symlink $HOME/data"
        # log_warning "Remove symlink $HOME/data"
        # rm "$HOME/$sourceDataDirectory"
        # ln -s "/data" "$HOME/$sourceDataDirectory"
      else
        # It's a directory!
        log_debug "Remove directory $HOME/data"
        rm -R "${DATADIR}/${sourceDataDirectory}:?"
        ln -s "/data" "$HOME/$sourceDataDirectory"
      fi
    else
      log_debug "Link directory $HOME/data"
      ln -s "/data" "$HOME/$sourceDataDirectory"
    fi

    linkDataDirectories=(
    "bin"
    # "Development"
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Videos"
    "ownCloud"
    "VirtualMachines"
    "Dropbox"
    "GoogleDrive"
    "SpiderOak Hive"
    "Software"
    ".thunderbird"
    ".cxoffice"
    ".atom"
    ".nylas"
    '.mozilla'
    )

    log_info "linkDataDirectories ${linkDataDirectories[*]}"

    for sourceLinkDirectory in "${linkDataDirectories[@]}"; do
      # log_debug "Link directory = $sourceLinkDirectory"
      # remove after testing
      # mkdir -p "/data/$sourceLinkDirectory"
      # up to here
      if [ -e "$HOME/$sourceLinkDirectory" ]; then
        if [ -d "$HOME/$sourceLinkDirectory" ]; then
          if [ -L "$HOME/$sourceLinkDirectory" ]; then
            # It is a symlink!
            # log_debug "Remove symlink $HOME/$sourceLinkDirectory"
            # rm "$HOME/$sourceLinkDirectory"
            ln -sf "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          else
            # It's a directory!
            # log_debug "Remove directory $HOME/data"
            rmdir "$HOME/$sourceLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          fi
        else
          rm "$HOME/$sourceLinkDirectory"
          ln -sf "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
        fi
      else
        # log_debug "$HOME/$sourceLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOME/$sourceLinkDirectory" ];  then
          # It is a symlink!
          # log_debug "Remove symlink $HOME/$sourceLinkDirectory"
          # rm "$HOME/$sourceLinkDirectory"
          ln -sf "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
        else
          ln -s "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
        fi
        # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
      fi
    done

    # Link DataDirectories from sub dirs to specified home dir
    linkDataDirectories=(
    "vagrant/vagrant" "vagrant"
    "vagrant/.vagrant.d" ".vagrant.d"
    )

    log_info "linkDataDirectories ${linkDataDirectories[*]}"
    count=$(((${#linkDataDirectories[@]}+1)/2))

    for (( i = 0; i <= count; i+=2 )); do
      sourceLinkDirectory=${linkDataDirectories[i]}
      targetLinkDirectory=${linkDataDirectories[i+1]}
      # remove after testing
      # mkdir -p "/data/$sourceLinkDirectory"
      # up to here
      # log_debug "sourceLinkDirectoryLink directory = $sourceLinkDirectory; targetLinkDirectory = $targetLinkDirectory"
      if [ -e "$HOME/$targetLinkDirectory" ]; then
        if [ -d "$HOME/$targetLinkDirectory" ]; then
          if [ -L "$HOME/$targetLinkDirectory" ]; then
            # It is a symlink!
            # log_debug "Remove symlink $HOME/$targetLinkDirectory"
            rm "$HOME/$targetLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          else
            # It's a directory!
            # log_debug "Remove directory $HOME/data"
            rmdir "$HOME/$targetLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          fi
        else
          rm "$HOME/$targetLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
        fi
      else
        # log_debug "$HOME/$targetLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOME/$targetLinkDirectory" ];  then
          # It is a symlink!
          # log_debug "Remove symlink $HOME/$targetLinkDirectory"
          rm "$HOME/$targetLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$targetLinkDirectory"
        fi
        ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
        # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$targetLinkDirectory"
      fi
    done
  fi
  cd "$currentPath" || exit
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                 Physical Machine Setup                                   O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# ownCloud Client Application Install
ownCloudClientInstallApp () {
  log_info "ownCloud Install"
  println_blue "ownCloud Install                                                     "

  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the ownCloud repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      if [[ $noCurrentReleaseRepo == 1 ]]; then
        wget -q -O - "https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$previousStableReleaseVer/Release.key" | sudo apt-key add -
        echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$previousStableReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$previousStableReleaseName.list"
      elif [[ $betaAns == 1 ]]; then
        wget -q -O - "https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$stableReleaseVer/Release.key" | sudo apt-key add -
        echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$stableReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$stableReleaseName.list"
      else
        wget -q -O - "https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$distReleaseVer/Release.key" | sudo apt-key add -
        echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$distReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$distReleaseName.list"
      fi
      repoUpdate
    fi
  fi
  sudo apt install -yf owncloud-client
}

# ############################################################################
# DisplayLink Software install
displayLinkInstallApp () {

  currentPath=$(pwd)
  log_info "display Link Install App"
  println_blue "display Link Install App                                             "
	sudo apt install -y libegl1-mesa-drivers xserver-xorg-video-all xserver-xorg-input-all dkms libwayland-egl1-mesa

  cd "$HOME/tmp" || return
	wget -r -t 10 --output-document="$HOME/tmp/displaylink.zip"  http://www.displaylink.com/downloads/file?id=1304
  mkdir -p "$HOME/tmp/displaylink"
  unzip "$HOME/tmp/displaylink.zip" -d "$HOME/tmp/displaylink/"
  chmod +x "$HOME/tmp/displaylink/displaylink-driver-5.1.run"
  sudo "$HOME/tmp/displaylink/displaylink-driver-5.1.run"

  sudo chown -R "$USER":"$USER" "$HOME/tmp/displaylink/"
  cd "$currentPath" || return
  sudo apt install -yf
}

# ############################################################################
# OpenVPN installation
openvpnInstall () {
  log_info "Install OpenVPN"
  println_blue "Install OpenVPN                                                      "
  sudo apt install -y openvpn network-manager-openvpn ca-certificates
  sudo service network-manager restart
  "$HOME/bin/nordvpnUpdate.sh"
}

# ############################################################################
# XPS Display Drivers installations
laptopDisplayDrivers () {
  log_info "Install XPS Display Drivers"
  println_blue "Install XPS Display Drivers                                          "
  #get intel key for PPA that gets added during install
  wget --no-check-certificate https://download.01.org/gfx/RPM-GPG-GROUP-KEY-ilg -O - | sudo apt-key add -
  sudo apt install -y nvidia-current intel-graphics-update-tool
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                   Window Managers and Backports                          O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# gnome3Backports
gnome3Backports () {
  log_info "Install Gnome3 Backports"
  println_blue "Install Gnome3 Backports                                                      "
  sudo add-apt-repository -y ppa:gnome3-team/gnome3-staging
  sudo add-apt-repository -y ppa:gnome3-team/gnome3
  if [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
  log_warning "No new repo, revert the Gnome3 apt sources."
  println_red "No new repo, revert the Gnome3 apt sources."
  changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-staging-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Gnome3 apt sources."
    println_red "No new repo, revert the Gnome3 apt sources."
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-staging-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  elif [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Gnome3 apt sources."
    println_red "Beta Code, revert the Gnome3 apt sources."
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-staging-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi

  sudo apt install -y gnome gnome-shell
}

# ############################################################################
# gnome3Settings
gnome3Settings () {
  log_info "Change Gnome3 settings"
  println_blue "Change Gnome3 settings                                               "
	gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
  gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  case $desktopEnvironment in
    gnome )
      # enable minimize on click for the Ubuntu Dock
      gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
    ;;
    ubuntu )
      # enable minimize on click for the Ubuntu Dock
      gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
    ;;
  esac
}

# ############################################################################
# kdeBetaBackportsRepo
kdeBetaBackportsRepo () {
  log_info "Add KDE Beta Backports Repo"
  println_blue "Add KDE Beta Backports Repo                                               "
  sudo add-apt-repository -y ppa:kubuntu-ppa/beta
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the KDE Backports Beta apt sources."
    println_red "Beta Code, revert the KDE Backports Beta apt sources."
    changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-beta-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  # if [[ $noCurrentReleaseRepo == 1 ]]; then
  #   log_warning "No new repo, revert the KDE Backports Beta apt sources."
  #   println_red "No new repo, revert the KDE Backports Beta apt sources."
  #   changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-beta-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  #   repoUpdate
  # fi
}

# ############################################################################
# kdeBackportsApps
kdeBackportsApps () {
  log_info "Add KDE Backports"
  println_blue "Add KDE Backports                                                             "
  sudo add-apt-repository -y ppa:kubuntu-ppa/backports
  # sudo add-apt-repository -y ppa:kubuntu-ppa/backports-landing
  if [[ $betaAns == 1 ]] || [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Beta Code or no new repo, revert the KDE Backports apt sources."
    println_red "Beta Code or no new repo, revert the KDE Backports apt sources."
    changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    # changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-landing-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi

  repoUpdate
  repoUpgrade
  sudo apt full-upgrade -y;
}

# ############################################################################
# kde5Settings
kde5Settings () {
  log_info "Change KDE5 Desktop settings"
  println_blue "Change KDE5 Desktop settings                                               "
  kwriteconfig5 --file ~/.config/kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XIAS"
  kwriteconfig5 --file ~/.config/kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "H"
  qdbus org.kde.KWin /KWin reconfigure
}



# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                 Development Apps                                         O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Development packages installation
devAppsInstall() {
  currentPath=$(pwd)
  log_info "Dev Apps install"
  println_banner_yellow "Dev Apps install                                                     "

  sudo apt install -yf abs-guide idle3 idle3-tools eric eric-api-files maven geany;

  cd "$currentPath" || return
}

# ############################################################################
# Git packages installation
gitInstall() {
  currentPath=$(pwd)
  log_info "Git Apps install"
  println_banner_yellow "Git Apps install                                                     "
  sudo apt install -y gitk git-flow giggle gitg git-cola
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install Gitkraken from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install --classic gitkraken
    else
      wget -P "$HOME/tmp" https://release.gitkraken.com/linux/gitkraken-amd64.deb
      sudo apt install -y "$HOME/tmp/gitkraken-amd64.deb"
    fi
  else
    wget -P "$HOME/tmp" https://release.gitkraken.com/linux/gitkraken-amd64.deb
    sudo apt install -y "$HOME/tmp/gitkraken-amd64.deb"
  fi

  sudo apt install -yf
  cd "$currentPath" || return
}

# ############################################################################
# Git Config with my details
gitConfig (){
  read -rp "Please enter your Git user name?" git_userName
  read -rp "Please enter your Git user email address?" git_user_email

  git config --global user.email "$git_user_email"
  git config --global user.name "$git_userName"
}
# ############################################################################
# Bashdb packages installation
bashdbInstall() {
  currentPath=$(pwd)
  # case versions, if eoan then https://sourceforge.net/projects/bashdb/files/bashdb/5.0-1.1.0/bashdb-5.0-1.1.0.tar.bz2/download
  log_info "Bash Debugger 5.0-1.1.0 install"
  println_banner_yellow "Bash Debugger 5.0-1.1.0 install                                       "
  cd "$HOME/tmp" || die "Path $HOME/tmp does not exist."
  # wget https://netix.dl.sourceforge.net/project/bashdb/bashdb/4.4-1.0.1/bashdb-4.4-1.0.1.tar.gz
  curl -L -# -o bashdb.tar.bz2 https://sourceforge.net/projects/bashdb/files/bashdb/5.0-1.1.1/bashdb-5.0-1.1.0.tar.bz2/download
  tar -xjf "$HOME/tmp/bashdb.tar.bz2"
  cd "$HOME/tmp/bashdb-5.0-1.1.0" || die "Path bashdb-5.0-1.1.0 does not exist"
  ./configure
  make
  sudo make install

  cd "$currentPath" || die "Could not cd $currentPath."
}

# ############################################################################
# Brackets DevApp installation
atomInstall() {
  # Brackets
  println_blue "Atom Editor"
  log_info "Atom Editor"
  currentPath=$(pwd)
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install AtomEditor from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install --classic atom
      sudo apt install -yf shellcheck devscripts hunspell hunspell-af hunspell-en-gb
    else
      sudo apt install -y curl
      curl -sL https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
      sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
      repoUpdate
      sudo apt install -yf atom shellcheck devscripts hunspell hunspell-af hunspell-en-us hunspell-en-za hunspell-en-gb
    fi
  else
    sudo apt install -y curl
    curl -sL https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
    repoUpdate
    sudo apt install -yf atom shellcheck devscripts hunspell hunspell-af hunspell-en-us hunspell-en-za hunspell-en-gb
  fi
  cd "$currentPath" || return
  # apm install linter
}

# ############################################################################
# Brackets DevApp installation
bracketsInstall() {
  # Brackets
  println_blue "Brackets"
  log_info "Brackets"
  sudo snap install --classic brackets
}


# ############################################################################
# Eclipse Install
eclipseInstall() {
  println_blue "Eclipse"
  log_info "Eclipse"
  sudo snap install --classic eclipse
}

# ############################################################################
# Visual Studio Code Install
vscodeInstall() {
  println_blue "Visual Studio Code"
  log_info "Visual Studio Code"
  currentPath=$(pwd)
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install Visual Studio Code from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install --classic code
    else
      sudo apt install -y curl
      curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
      sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
      sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
      sudo apt install apt-transport-https
      repoUpdate
      sudo apt install code
    fi
  else
    sudo snap install --classic code
  fi
  cd "$currentPath" || return
}

# ############################################################################
# PyCharm Install
pycharmInstall() {
  println_blue "Pycharm"
  log_info "Pycharm"
  sudo snap install --classic pycharm-community
}

# ############################################################################
# Intellij Idea Community Install
intellij-idea-communityInstall() {
  println_blue "Intellij Idea Community"
  log_info "Intellij Idea Community"
  sudo snap install intellij-idea-community --classic
}


# ############################################################################
# LightTable packages installation
# Very old, suggest install from lightable.com
lightTableInstall() {
  currentPath=$(pwd)
  log_info "LightTable"
  println_blue "LightTable"
  sudo add-apt-repository -y ppa:dr-akulavich/lighttable
  log_warning "Change Lighttable to $ltsReleaseName"
  println_yellow "Change Lighttable to $ltsReleaseName"
  changeAptSource "/etc/apt/sources.list.d/dr-akulavich-ubuntu-lighttable-$distReleaseName.list" "$distReleaseName" "$ltsReleaseName"
  sudo apt install -y lighttable-installer
  cd "$currentPath" || return
}

# ############################################################################
# Postman DevApp installation
postmanInstall() {
  # Postman
  println_blue "Postman"
  log_info "Postman"
  sudo snap install --classic postman
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                   Apps Install                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Google Chrome Install
googleChromeInstall () {
  log_info "Google Chrome Install"
  println_blue "Google Chrome Install"
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list
  repoUpdate
  sudo apt install -y google-chrome-stable
}

# ############################################################################
# Install Fonts
fontsInstall () {
  log_info "Install Fonts"
  println_blue "Install Fonts"
  sudo apt install -y cabextract fonts-3270 fonts-breip fonts-dejavu fonts-dejavu-core fonts-dejavu-extra fonts-dkg-handwriting fonts-dustin fonts-firacode fonts-georgewilliams fonts-hack fonts-hack-otf fonts-hack-ttf fonts-hack-web fonts-inconsolata fonts-isabella t1-xfree86-nonfree ttf-aenigma ttf-bitstream-vera ttf-dejavu ttf-dejavu-extra ttf-mscorefonts-installer ttf-sjfonts ttf-staypuft ttf-summersby ttf-xfree86-nonfree ;
}

# ############################################################################
# Cheat command line cheatsheet installation
cliCheatsheetInstall() {
  # Brackets
  println_blue "Cheat the cheatsheet for the commandline"
  log_info "Cheat the cheatsheet for the commandline"
  sudo snap install cheat
}

# ############################################################################
# Install Opera browser
operaInstall () {
  log_info "Install Opera browser"
  println_blue "Install Opera browser"
  sudo snap install --classic opera
}

# ############################################################################
# Install Thunderbird
thunderbirdInstall () {
  log_info "Install Thunderbird email client"
  println_blue "Install Thunderbird email client"
  sudo apt install -y thunderbird;
}

# ############################################################################
# Install Evolution
evolutionInstall () {
  log_info "Install Evolution email client"
  println_blue "Install Evolution email client"
  sudo apt install -y  evolution evolution-ews gnome-online-accounts gnome-control-center;
}

# ############################################################################
# Install Mailspring
mailspringInstall () {
  log_info "Install Mailspring desktop email client"
  println_blue "Install Mailspring desktop email client"
  currentPath=$(pwd)
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install Mailspring from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install --classic mailspring
    else
      wget -P "$HOME/tmp" https://updates.getmailspring.com/download?platform=linuxDeb
      sudo apt install -y "$HOME/tmp/mailspring.deb"
    fi
  else
    sudo snap install --classic mailspring
    # wget -P "$HOME/tmp" -O mailspring.deb https://updates.getmailspring.com/download?platform=linuxDeb
    # sudo apt install -y "$HOME/tmp/mailspring.deb"
  fi
  sudo apt install -yf
  cd "$currentPath" || return
}

# ############################################################################
# Install Winds
windsInstall () {
  log_info "Install Winds RSS Reader and Podcast application"
  println_blue "Install Winds RSS Reader and Podcast application"
  sudo snap install --classic winds
}
# ############################################################################
# Install Tusk Evernote app
tuskInstall () {
  log_info "Install Tusk Evernote application"
  println_blue "Install Tusk Evernote application"
  sudo snap install --classic tusk
}

# ############################################################################
# Install Skype
skypeInstall () {
  log_info "Install Skype"
  println_blue "Install Skype"
  sudo snap install --classic skype
}

# ############################################################################
# Install Slack
slackInstall () {
  log_info "Install Slack"
  println_blue "Install Slack"
  sudo snap install --classic slack
}

# ############################################################################
# Install Xtreme Download Manager
xdmanInstall () {
  log_info "Install Xtreme Download Manager media center"
  println_blue "Install Xtreme Download Manager media center"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Kodi repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo add-apt-repository -y ppa:team-xbmc/ppa
      if [[ $betaAns == 1 ]]; then
        log_warning "Beta Code, revert the Xtreme Download Manager apt sources."
        println_red "Beta Code, revert the Xtreme Download Manager apt sources."
        changeAptSource "/etc/apt/sources.list.d/noobslab-ubuntu-apps-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      elif [[ $noCurrentReleaseRepo == 1 ]]; then
        log_warning "No new repo, revert the Xtreme Download Manager apt sources."
        println_red "No new repo, revert the Xtreme Download Manager apt sources."
        changeAptSource "/etc/apt/sources.list.d/noobslab-ubuntu-apps-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      elif [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
        log_warning "No new repo, revert the Xtreme Download Manager apt sources."
        println_red "No new repo, revert the Xtreme Download Manager apt sources."
        changeAptSource "/etc/apt/sources.list.d/noobslab-ubuntu-apps-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      fi
    fi
  fi
  sudo apt install -y xdman
}


# ############################################################################
# Install inSync for GoogleDrive
insyncInstall () {
  log_info "Install inSync for GoogleDrive"
  println_blue "Install inSync for GoogleDrive"
  if [[  $betaAns != 1 ]] && [[ $noCurrentReleaseRepo != 1 ]]; then
    echo "deb http://apt.insynchq.com/ubuntu $distReleaseName non-free contrib" | sudo tee "/etc/apt/sources.list.d/insync-$distReleaseName.list"
  elif [[ $betaAns == 1 ]]; then
    echo "deb http://apt.insynchq.com/ubuntu $stableReleaseName non-free contrib" | sudo tee "/etc/apt/sources.list.d/insync-$stableReleaseName.list"
  else
    echo "deb http://apt.insynchq.com/ubuntu $previousStableReleaseName non-free contrib" | sudo tee "/etc/apt/sources.list.d/insync-$previousStableReleaseName.list"
  fi
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
  repoUpdate
  sudo apt install -y insync
}

# ############################################################################
# Install Doublecmd
doublecmdInstall () {
  log_info "Install Doublecmd"
  println_blue "Install Doublecmd"
  # wget -nv https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_18.04/Release.key -O "$HOME/tmp/Release.key" | sudo apt-key add -
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Doublecmd repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      if [[ $betaAns != 1 ]] && [[ $noCurrentReleaseRepo != 1 ]]; then
        wget -q "https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_$distReleaseVer/Release.key" -O- | sudo apt-key add -
        echo "deb http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_$distReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/Alexx2000-$distReleaseName.list"
      elif [[ $betaAns == 1 ]]; then
        wget -q "https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_$stableReleaseVer/Release.key" -O- | sudo apt-key add -
        echo "deb http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_$stableReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/Alexx2000-$stableReleaseName.list"
      else
        wget -q "https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_$previousStableReleaseVer/Release.key" -O- | sudo apt-key add -
        echo "deb http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_$previousStableReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/Alexx2000-$previousStableReleaseName.list"
      fi
      repoUpdate
    fi
  fi
  case $desktopEnvironment in
    "kde" )
      sudo apt install -y doublecmd-qt doublecmd-help-en doublecmd-plugins
      ;;
    "gnome" )
      sudo apt install -y doublecmd-gtk doublecmd-help-en doublecmd-plugins
      ;;
    "ubuntu" )
      sudo apt install -y doublecmd-common doublecmd-help-en doublecmd-plugins
      ;;
    "xubuntu" )
      sudo apt install -y doublecmd-common doublecmd-help-en doublecmd-plugins
      ;;
    "lubuntu" )
      sudo apt install -y doublecmd-common doublecmd-help-en doublecmd-plugins
      ;;
  esac
}

# ############################################################################
# KVM Install
kvmInstall () {
  log_info "KVM Applications Install"
  println_blue "KVM Applications Install                                               "

  if [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
    sudo apt install -y qemu-kvm libvirt-clients libvirt-daemon virtinst bridge-utils cpu-checker virt-manager linux-image-kvm linux-kvm linux-image-virtual linux-tools-kvm aqemu
  else
    sudo apt install -y qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker virt-manager

  fi
  case $desktopEnvironment in
    "kde" )
      sudo apt install -y aqemu qt-virt-manager
      ;;
    "gnome" )
      sudo apt install -y gnome-boxes
      ;;
    "ubuntu" )
      sudo apt install -y gnome-boxes
      ;;
    "xubuntu" )
      # sudo apt install -y gmountiso;
      ;;
    "lubuntu" )
      # sudo apt install -y gmountiso;
      ;;
  esac

}

# ############################################################################
# Configure DockerInstall
dockerInstall () {
  currentPath=$(pwd)
  log_info "Configure Docker Install"
  println_blue "Configure Docker Install"
	# Purge the old repo
	sudo apt purge -y lxc-docker docker-engine docker.io
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Doublecmd repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      if [[ $betaAns != 1 ]] && [[ $noCurrentReleaseRepo != 1 ]]; then
        # log_warning "Add Docker to repository."
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $distReleaseName stable" | sudo tee "/etc/apt/sources.list.d/docker-$distReleaseName.list"
      elif [[ $betaAns == 1 ]]; then
        log_info "Add Docker to repository with stable release $stableReleaseName"
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $stableReleaseName stable" | sudo tee "/etc/apt/sources.list.d/docker-$stableReleaseName.list"
      else
        log_info "Add Docker to repository with stable release $previousStableReleaseName"
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $previousStableReleaseName stable" | sudo tee "/etc/apt/sources.list.d/docker-$previousStableReleaseName.list"
      fi
      repoUpdate;
      # Make sure that apt is pulling from the right repository
      # sudo apt-cache policy docker-engine
      sudo apt-cache policy docker-ce

      # Add the additional kernel packages and install Docker
      # sudo apt install -y "build-essential linux-headers-$kernelRelease linux-image-extra-$kernelRelease" linux-image-extra-virtual
      sudo apt install -y linux-image-extra-virtual docker-ce
    else
      sudo apt install -y linux-image-extra-virtual docker.io
    fi
  else
    sudo apt install -y linux-image-extra-virtual docker.io
  fi


	# Change the images and containers directory to /data/docker
	# Un comment the following if it is a new install and comment the rm line
	# sudo mv /var/lib/docker /data/docker
  if [ -d "$HOME/data" ]; then
  # if /data exists then link docker directory to /data/docker.
    if [[ $(sudo docker ps -q) = 1 ]]; then
      sudo docker ps -q | xargs docker kill
    fi
    # sudo docker ps -q | xargs docker kill
    sudo systemctl stop docker
    # sudo cd /var/lib/docker/devicemapper/mnt
    # sudo umount ./*
    # sudo mv /var/lib/docker/ /data/docker/
    sudo rm -Rf /var/lib/docker
    sudo ln -s /data/docker /var/lib/docker

    #Add the new /data/docker directory to the config file
    # The following line sets the DNS as well
    # sudo sed -i '$a DOCKER_OPTS="-dns 8.8.8.8 -dns 8.8.4.4 -g /mnt"' /etc/default/docker
    # Following does not set the DNS
    sudo sed -i '$a DOCKER_OPTS="-g /data/docker"' /etc/default/docker
    #Start the docker deamon
    sudo service docker start
  fi

	# Create docker group and add juanb
  sudo groupadd docker
	sudo usermod -aG docker "$USER"
	printf "Logout and login for the user to be added to the group\\n"
	printf "\\nGo to https://docs.docker.com/engine/installation/ubuntulinux/ for DNS and Firewall setup\\n\\n"
  pressEnterToContinue

  sudo ufw allow 2375/tcp
  cd "$currentPath" || return
  sudo apt install -yf
}

# #########################################################################
# Install Dropbox Application
dropboxInstall () {
  log_info "Dropbox Install"
  println_blue "Dropbox Install"
  rm -R "${HOMEDIR}/.dropbox-dist/*:?"
  cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to start the Dropbox initiation and setup? (Y/N)" answer
    if [[ $answer = [Yy1] ]]; then
      ~/.dropbox-dist/dropboxd
    fi
  fi
}

# ############################################################################
# Ruby Repository directories to host
rubyRepo () {
  log_info "Ruby Repo"
  println_blue "Ruby Repo"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Ruby repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo apt-add-repository -y ppa:brightbox/ruby-ng
      if [[ $noCurrentReleaseRepo == 1 ]]; then
        log_warning "No new repo, revert the Ruby Repo apt sources."
        println_red "No new repo, revert the Ruby Repo apt sources."
        changeAptSource "/etc/apt/sources.list.d/brightbox-ubuntu-ruby-ng-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        repoUpdate
      elif [[ $betaAns == 1 ]]; then
        log_warning "Beta Code, revert the Ruby Repo apt sources."
        println_red "Beta Code, revert the Ruby Repo apt sources."
        changeAptSource "/etc/apt/sources.list.d/brightbox-ubuntu-ruby-ng-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      elif [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
        log_warning "No new repo, revert the Ruby Repo apt sources."
        println_red "No new repo, revert the Ruby Repo apt sources."
        changeAptSource "/etc/apt/sources.list.d/brightbox-ubuntu-ruby-ng-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        repoUpdate
      fi
    fi
  fi
  sudo apt install -yf ruby ruby-dev ruby-dnsruby
}

# ############################################################################
# Vagrant Install, vmtools, nfs directories to host
vagrantInstall () {
  log_info "Vagrant Applications Install"
  println_blue "Vagrant Applications Install                                               "
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install the Ruby repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      rubyRepo
    fi
  fi
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Vagrant repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo add-apt-repository -y ppa:tiagohillebrandt/vagrant
      if [[ $betaAns == 1 ]]; then
        log_warning "Beta Code, revert the Vagrant apt sources."
        println_red "Beta Code, revert the Vagrant apt sources."
        changeAptSource "/etc/apt/sources.list.d/tiagohillebrandt-ubuntu-vagrant-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      elif [[ $noCurrentReleaseRepo == 1 ]]; then
        log_warning "No new repo, revert the Vagrant apt sources."
        println_red "No new repo, revert the Vagrant apt sources."
        changeAptSource "/etc/apt/sources.list.d/tiagohillebrandt-ubuntu-vagrant-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        repoUpdate
      elif [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
        log_warning "No new repo, revert the Vagrant apt sources."
        println_red "No new repo, revert the Vagrant apt sources."
        changeAptSource "/etc/apt/sources.list.d/tiagohillebrandt-ubuntu-vagrant-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        repoUpdate
      fi
    fi
  fi

  sudo apt install -yf dnsutils vagrant vagrant-cachier vagrant-sshfs ruby ruby-dev ruby-dnsruby libghc-zlib-dev ifupdown numad radvd auditd systemtap zfsutils pm-utils;

  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install Vagrant KVM support? (Y/N)" answer
    if [[ $answer = [Yy1] ]]; then
      sudo apt install -yf libvirt-clients libvirt-daemon vagrant-libvirt;
    fi
  # else
    # sudo apt install -yf libvirt-clients libvirt-daemon vagrant-libvirt;
  fi

  vagrant plugin install vagrant-vbguest vagrant-dns vagrant-registration vagrant-gem vagrant-auto_network vagrant-sshf
  sudo gem install rubydns nio4r pristine hitimes libvirt libvirt-ruby ruby-libvirt rb-fsevent nokogiri vagrant-dns
}

# ############################################################################
# AsciiDoc packages installation
asciiDocInstall() {
  currentPath=$(pwd)
  log_info "AsciiDoc Apps install"
  println_banner_yellow "AsciiDoc Apps install                                                     "

  # rubyRepo
  # repoUpdate
  sudo apt install -y asciidoctor graphviz asciidoc umlet pandoc asciidoctor ruby plantuml;
  sudo gem install bundler guard rake asciidoctor-diagram asciidoctor-plantuml
  cd "$currentPath" || return
}

# ############################################################################
# Syncwall, WoeUSB packages installation
webupd8AppsInstall() {
  log_info "WebUpd8: SyncWall, ?WoeUSB? Applictions Install"
  println_blue "WebUpd8: SyncWall, WoeUSB Applications Install"
  sudo add-apt-repository -y ppa:nilarimogard/webupd8
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the WebUpd8 apt sources."
    println_red "Beta Code, revert the WebUpd8 apt sources."
    changeAptSource "/etc/apt/sources.list.d/nilarimogard-ubuntu-webupd8-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the WebUpd8 apt sources."
    println_red "No new repo, revert the WebUpd8 apt sources."
    changeAptSource "/etc/apt/sources.list.d/nilarimogard-ubuntu-webupd8-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi

  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install Syncwall? (Y/N)" answer
    if [[ $answer = [Yy1] ]]; then
      sudo apt install -y syncwall
    fi
    read -rp "Do you want to install WoeUSB? (Y/N)" answer
    if [[ $answer = [Yy1] ]]; then
      sudo apt install -y woeusb
    fi
  else
    sudo apt install -y syncwall woeusb
  fi
}

# ############################################################################
# Y-PPA Manager packages installation
yppaManagerInstall() {
  log_info "Y-PPA Manager Appliction Install"
  println_blue "Y-PPA Manager Application Install"
  sudo add-apt-repository -y ppa:webupd8team/y-ppa-manager
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Codeo, revert the Y-PPA Manager apt sources."
    println_red "Beta Code, revert the Y-PPA Manager apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Beta Code or no new repo, revert the Y-PPA Manager apt sources."
    println_red "Beta Code or no new repo, revert the Y-PPA Manager apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi
  sudo apt install -y y-ppa-manager
}

# ############################################################################
# OpenJDK Versions installation
openJDK8Install() {
  log_info "OpenJDK 8 Installation"
  println_blue "OpenJDK 8 Installation"
  sudo apt install -y openjdk-8-jdk openjdk-8-jre openjdk-8-doc
}

openJDK11Install() {
  log_info "OpenJDK 11 Installation"
  println_blue "OpenJDK 11 Installation"
  sudo apt install -y openjdk-11-jdk openjdk-11-jre openjdk-11-doc
}

openJDKLatestInstall() {
  log_info "OpenJDK Latest Installation"
  println_blue "OpenJDK Latest Installation"
  sudo apt install -y openjdk-14-jdk openjdk-14-jre openjdk-14-doc
}

# ############################################################################
# Oracle Java Installer from WebUpd8 packages installation
oracleJava8Install() {
  log_info "Oracle Java8 Installer from WebUpd8"
  println_blue "Oracle Java8 Installer from WebUpd8"
  sudo add-apt-repository -y ppa:webupd8team/java
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Oracle Java 8 apt sources."
    println_red "Beta Code, revert the Oracle Java 8 apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Oracle Java 8 apt sources."
    println_red "No new repo, revert the Oracle Java 8 apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate

  fi
  sudo apt install -y oracle-java8-installer
}

oracleJava11Install() {
  log_info "Oracle Java11 Installer from WebUpd8"
  println_blue "Oracle Java11 Installer from WebUpd8"
  sudo add-apt-repository -y ppa:webupd8team/java
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Oracle Java 11 apt sources."
    println_red "Beta Code, revert the Oracle Java 11 apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Oracle Java 11 apt sources."
    println_red "No new repo, revert the Oracle Java 11 apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate

  fi
  sudo apt install -y oracle-java11-installer
  sudo apt install -y oracle-java11-set-default
}


oracleJavaLatestInstall() {
  log_info "Oracle Java Latest Installer from WebUpd8"
  println_blue "Oracle Java Latest Installer from WebUpd8"
  sudo add-apt-repository -y ppa:linuxuprising/java
  # if [[ $noCurrentReleaseRepo == 1 ]]; then
  #   log_warning "Repos not available as yet, downgrade Oracle Java Latest Installer apt sources."
  #   # println_red "Repos not available as yet, downgrade Oracle Java Installer apt sources."
  #   changeAptSource "/etc/apt/sources.list.d/linuxuprising-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  # fi
  sudo apt install -y oracle-java12-installer
  sudo apt install -y oracle-java12-set-default
  sudo update-alternatives --config java
  # Add JAVA_HOME to .bash_profile
  if [[ ! -f "$HOME/.bash_profil"e ]]; then
    touch "$HOME/.bash_profile"
    chmod +x "$HOME/.bash_profile"
  fi
  sed -i -e 'export JAVA_HOME="/usr/lib/jvm/java-12-oracle"' "$HOME/.bash_profile"
  source /etc/environment
  echo "$JAVA_HOME"
}


# ############################################################################
# Set Java Version
setJavaVersion(){
    log_info "Set Java Version"
    println_blue "Set Java Version"
    sudo update-alternatives --config java
}

# ############################################################################
# Grub Customizer packages installation
grubCustomizerInstall() {
  log_info "Grub Customizer Appliction Install"
  println_blue "Grub Customizer Application Install"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Grub Customizer repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
      if [[ $betaAns == 1 ]]; then
        log_warning "Beta Distribution, downgrade Grub Customizer apt sources."
        println_red "Beta Distribution, downgrade Grub Customizer apt sources."
        changeAptSource "/etc/apt/sources.list.d/danielrichter2007-ubuntu-grub-customizer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
      fi
    fi
  fi
  sudo apt install -y grub-customizer
}

# ############################################################################
# Variety packages installation
varietyInstall() {
  log_info "Variety Appliction Install"
  println_blue "Variety Application Install"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Variety repo? This will enable Variety Slideshow.(y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo add-apt-repository -y ppa:peterlevi/ppa
      # sudo add-apt-repository -y ppa:variety/daily

      sudo apt install -y variety variety-slideshow python3-pip
    fi
  fi
  sudo apt install -y variety python3-pip
  sudo pip3 install ndg-httpsclient # For variety
}

# ############################################################################
# Boot Repair packages installation
bootRepairInstall() {
  log_info "Boot Repair Appliction Install"
  println_blue "Boot Repair Application Install"
  sudo add-apt-repository -y ppa:yannubuntu/boot-repair
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Boot Repair apt sources."
    println_red "Beta Code, revert the Boot Repair apt sources."
    changeAptSource "/etc/apt/sources.list.d/yannubuntu-ubuntu-boot-repair-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Boot Repair apt sources."
    println_red "No new repo, revert the Boot Repair apt sources."
    changeAptSource "/etc/apt/sources.list.d/yannubuntu-ubuntu-boot-repair-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi
  sudo apt install -y boot-repair
}

# ############################################################################
# UNetbootin packages installation
unetbootinInstall() {
  log_info "UNetbootin Appliction Install"
  println_blue "UNetbootin Application Install"
  sudo add-apt-repository -y ppa:gezakovacs/ppa
  if [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
    log_warning "No new repo, revert the UNetbootin apt sources."
    println_red "No new repo, revert the UNetbootin apt sources."
    changeAptSource "/etc/apt/sources.list.d/gezakovacs-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the UNetbootin apt sources."
    println_red "No new repo, revert the UNetbootin apt sources."
    changeAptSource "/etc/apt/sources.list.d/gezakovacs-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  elif [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the UNetbootin apt sources."
    println_red "Beta Code, revert the UNetbootin apt sources."
    changeAptSource "/etc/apt/sources.list.d/gezakovacs-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  sudo apt install -y unetbootin
}

# ############################################################################
# Etcher USB Creater install
etcherInstall () {
  log_info "Install Etcher USB loader"
  println_blue "Install Etcher USB loader"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the repo(default) or AppImage? (repo/appimage)" answer
  fi
  if [[ $answer = "appimage" ]]; then
    curl -s https://github.com/resin-io/etcher/releases/latest | grep "balenaEtcher-*-x64.AppImage
" | cut -d '"' -f 4   | wget -qi -
  else
    echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
    # if [[ $betaAns == 1 ]]; then
    #   changeAptSource "/etc/apt/sources.list.d/-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    # elif [[ $noCurrentReleaseRepo == 1 ]]; then
    #   changeAptSource "/etc/apt/sources.list.d/-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    # fi
    repoUpdate
    sudo apt install -y balena-etcher-electron
    # sudo apt install -y etcher-electron
  fi
}

# ############################################################################
# rEFInd Boot Manager packages installation
rEFIndInstall() {
  log_info "rEFInd Boot Manager Appliction Install"
  println_blue "rEFInd Boot Manager Application Install"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the rEFInd repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo apt-add-repository -y ppa:rodsmith/refind
    fi
  fi

  sudo apt install -y refind
}

# ############################################################################
# rEFInd Boot Manager packages installation
batteryManagerInstall() {
  log_info "Battery Manager Appliction Install"
  println_blue "Battery Manager Application Install"
  sudo add-apt-repository ppa:slimbook/slimbook
  sudo apt install -y slimbookbattery
}

# ############################################################################
# Stacer Linux system info and cleaner packages installation
stacerInstall() {
  log_info "Stacer Linux System Optimizer and Monitoring Appliction Install"
  println_blue "Stacer Linux System Optimizer and Monitoring Application Install"
  sudo add-apt-repository -y ppa:oguzhaninan/stacer
  if [[ "$distReleaseName" =~ ^("$betaReleaseName")$ ]]; then
    log_warning "No new repo, revert the Stacer apt sources."
    println_red "No new repo, revert the Stacer apt sources."
    changeAptSource "/etc/apt/sources.list.d/oguzhaninan-ubuntu-stacer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Stacer apt sources."
    println_red "No new repo, revert the Stacer apt sources."
    changeAptSource "/etc/apt/sources.list.d/oguzhaninan-ubuntu-stacer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Stacer apt sources."
    println_red "Beta Code, revert the Stacer apt sources."
    changeAptSource "/etc/apt/sources.list.d/oguzhaninan-ubuntu-stacer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  sudo apt install -y stacer
  # AppImage
  # wget https://github.com/oguzhaninan/Stacer/releases/download/v1.0.9/Stacer-x86_64.AppImage
}

# ############################################################################
# Bitwarden Password manager packages installation
bitwardenInstall() {
  log_info "Bitwarden Password Manager Appliction Install"
  println_blue "Bitwarden Password Manager Application Install"
  sudo snap install --classic bitwarden
}

# ############################################################################
# getdeb repository installation
# getdeb seems to be dead
getdebRepository() {
  log_info "getdeb Repository Install"
  println_blue "getdeb Repository Install"
  log_warning "getdeb Repository is set at Zesty"
  println_yellow "getdeb Repository is set at Zesty"
  # GetDeb for Filezilla, PyCharm, Calibre, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync
  log_info "Filezilla, PyCharm, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync"
  println_blue "Filezilla, PyCharm, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync"
  wget -q -O - http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
  sudo sh -c 'echo "deb http://archive.getdeb.net/ubuntu zesty-getdeb apps" >> /etc/apt/sources.list.d/getdeb-zesty.list'
  # Downgrade getdeb as there are no current repos
  # sudo sh -c "echo 'deb http://archive.getdeb.net/ubuntu $distReleaseName-getdeb apps' >> /etc/apt/sources.list.d/getdeb-$distReleaseName.list"
}

# ############################################################################
# FreeFileSync installation
FreeFileSyncInstall() {
  log_info "FreeFileSync Appliction Install"
  println_blue "FreeFileSync Application Install"
  pressEnterToContinue "FreeFileSync needs to be manually installed."
  # getdebRepository
  # sudo apt install -y freefilesync
}

# ############################################################################
# Latte Dock for KDE packages installation
latteDockInstall() {
  log_info "Latte Dock for KDE Install"
  println_blue "Latte Dock for KDE Install"
  # sudo add-apt-repository -y ppa:rikmills/latte-dock
  # sudo apt install cmake extra-cmake-modules qtdeclarative5-dev libqt5x11extras5-dev libkf5iconthemes-dev libkf5plasma-dev libkf5windowsystem-dev libkf5declarative-dev libkf5xmlgui-dev libkf5activities-dev build-essential libxcb-util-dev libkf5wayland-dev git gettext libkf5archive-dev libkf5notifications-dev libxcb-util0-dev libsm-dev libkf5crash-dev libkf5newstuff-dev
  sudo apt install -y latte-dock
  kwriteconfig5 --file "$HOME/.config/kwinrc" --group ModifierOnlyShortcuts --key Meta "org.kde.lattedock,/Latte,org.kde.LatteDock,activateLauncherMenu"
  qdbus org.kde.KWin /KWin reconfigure
}

# ############################################################################
# LibreCAD installation
librecadInstall() {
  log_info "Install LibreCAD"
  println_blue "Install LibreCAD"

  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the LibreCAD Daily Dev repo? (y/n))" answer
    if [[ $answer = [yY1] ]]; then
      # sudo add-apt-repository -y ppa:librecad-dev/librecad-stable
      sudo add-apt-repository -y ppa:librecad-dev/librecad-daily
      if [[ $betaAns == 1 ]]; then
        log_warning "Beta Code, revert the LibreCAD apt sources."
        println_red "Beta Code, revert the LibreCAD apt sources."
        changeAptSource "/etc/apt/sources.list.d/librecad-dev-ubuntu-librecad-stable-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      elif [[ $noCurrentReleaseRepo == 1 ]]; then
        log_warning "No new repo, revert the LibreCAD apt sources."
        println_red "No new repo, revert the LibreCAD apt sources."
        changeAptSource "/etc/apt/sources.list.d/librecad-dev-ubuntu-librecad-stable-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        repoUpdate
      elif [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
        log_warning "No new repo, revert the LibreCAD apt sources."
        println_red "No new repo, revert the LibreCAD apt sources."
        changeAptSource "/etc/apt/sources.list.d/librecad-dev-ubuntu-librecad-stable-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        repoUpdate
      fi
    fi
  fi

  sudo apt install -y librecad
}

# ############################################################################
# Calibre installation
calibreInstall() {
  log_info "Calibre"
  println_blue "Calibre"

  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Calibre Download site? (y/n))" answer
    if [[ $answer = [yY1] ]]; then
        sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
    else
      sudo apt install -y calibre
    fi
  else
    sudo apt install -y calibre
  fi



  # sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
  # Use the following f you get certificate issues
  # sudo -v && wget --no-check-certificate -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

  # Github download, above is recommended
  # sudo -v && wget --no-check-certificate -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\\n'); exec(sys.stdin.read()); main()"
}

# ############################################################################
# Powerline installation
powerlineInstall() {
  log_info "Powerline"
  println_blue "Powerline"

  sudo apt install -y powerline powerline-doc powerline-gitstatus jsonlint
}

# ############################################################################
# KMyMoney installation
kMyMoneyInstall() {
  log_info "KMyMoney"
  println_blue "kMyMoney"

  sudo apt install -y kmymoney
}

# ############################################################################
# Favorite Book Reader installation
fbReaderInstall() {
  log_info "Favorite Book Reader"
  println_blue "Favorite Book Reader"

  sudo apt install -y fbreader
}

# ############################################################################
# Anbox installation
anboxInstall() {
  log_info "Anbox"
  println_blue "Anbox"

  sudo add-apt-repository -y ppa:morphis/anbox-support
  sudo apt install -y anbox-modules-dkms
  sudo modprobe ashmem_linux
  sudo modprobe binder_linux
  sudo snap install --devmode --beta anbox
  pressEnterToContinue 'Add "snap refresh --beta --devmode anbox" to bin/upgrade.sh for regular upgrades of Anbox'
}

# ############################################################################
# Bleachbit installation
bleachbitInstall() {
  log_info "Bleachbit"
  println_blue "Bleachbit"

  sudo apt install -y bleachbit
}

# ############################################################################
# Ambiance and Radiance Theme Color packages installation
ambianceRadianceThemeInstall() {
  log_info "Ambiance and Radiance Theme Color Install"
  println_blue "Ambiance and Radiance Theme Color Install"
  sudo add-apt-repository -y ppa:ravefinity-project/ppa
  if [[ "$distReleaseName" =~ ^($stableReleaseName|$betaReleaseName)$ ]]; then
      log_warning "Change ravefinity-project to $previousStableReleaseName"
      println_yellow "Change ravefinity-project to $previousStableReleaseName"
      changeAptSource "/etc/apt/sources.list.d/ravefinity-project-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  fi

}

# ############################################################################
# Inkscape packages installation
inkscapeInstall() {
  log_info "Inkscape Install"
  println_blue "Inkscape Install"
  # sudo snap install --classic inkscape
  sudo apt install -y inkscape
}

# ############################################################################
# Image Edfiting packages installation
imageEditingAppsInstall() {
  log_info "Imaging Editing Applications"
  println_blue "Imaging Editing Applications"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Gimp repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo add-apt-repository -y ppa:otto-kesselgulasch/gimp
    fi
  fi

  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install Gimp from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install --classic gimp
    else
      sudo apt install -y gimp
    fi
  else
    sudo apt install -y gimp
  fi

  # sudo apt install -y dia gimp gimp-plugin-registry gimp-ufraw;
  sudo apt install -y dia
}

# ############################################################################
# Music and Videos packages installation
musicVideoAppsInstall() {
  log_info "Music and Video apps"
  println_blue "Music and Video apps"
  sudo apt install -y easytag
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install Clementine from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install --classic clementine
    else
      sudo apt install -y clementine
    fi
  else
    sudo apt install -y clementine
  fi

  # sudo snap install vlc # default with ubuntu
}

# ############################################################################
# Install Spotify
spotifyInstall () {
  log_info "Install Spotify"
  println_blue "Install Spotify"
  sudo snap install --classic spotify
}

# ############################################################################
# Install Kodi media center
kodiInstall () {
  log_info "Install Kodi media center"
  println_blue "Install Kodi media center"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the Kodi repo? (y/n)" answer
    if [[ $answer = [yY1] ]]; then
      sudo add-apt-repository -y ppa:team-xbmc/ppa
      if [[ $betaAns == 1 ]]; then
        log_warning "Beta Code, revert the Kodi apt sources."
        println_red "Beta Code, revert the Kodi apt sources."
        changeAptSource "/etc/apt/sources.list.d/team-xbmc-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      elif [[ $noCurrentReleaseRepo == 1 ]]; then
        log_warning "No new repo, revert the Kodi apt sources."
        println_red "No new repo, revert the Kodi apt sources."
        changeAptSource "/etc/apt/sources.list.d/team-xbmc-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      elif [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
        log_warning "No new repo, revert the Kodi apt sources."
        println_red "No new repo, revert the Kodi apt sources."
        changeAptSource "/etc/apt/sources.list.d/team-xbmc-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
        repoUpdate
      fi
    fi
  fi
  sudo apt install -y kodi
}

# ############################################################################
# Install Google Play Music Desktop Player
google-play-music-desktop-playerInstall () {
  log_info "Install Google Play Music Desktop Player"
  println_blue "Install Google Play Music Desktop Player"
  sudo snap install --classic google-play-music-desktop-player
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O               Photography Apps                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# #########################################################################
# Install digikam Application
digikamInstall () {
  log_info "Digikam Install"
  println_blue "Digikam Install"
  sudo add-apt-repository -y ppa:kubuntu-ppa/backports
  # sudo add-apt-repository -y ppa:philip5/extra
  # sudo apt install -yf
	sudo apt install -yf digikam digikam-doc digikam-data
  # sudo apt install -yf
}

darktableInstall() {
  currentPath=$(pwd)
  log_info "Darktable Repo"
  println_blue "Darktable Repo"
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install darktable --classic
    else
      read -rp "Do you want to install from the Darktable repo? (y/n)" answer
      if [[ $answer = [yY1] ]]; then
        sudo add-apt-repository -y ppa:pmjdebruijn/darktable-release
        if [[ $betaAns == 1 ]]; then
          log_warning "Beta Code, revert the Darktable apt sources."
          println_red "Beta Code, revert the Darktable apt sources."
          changeAptSource "/etc/apt/sources.list.d/pmjdebruijn-ubuntu-darktable-release-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
          repoUpdate
        elif [[ $noCurrentReleaseRepo == 1 ]]; then
          log_warning "No new repo, revert the Darktable apt sources."
          println_red "No new repo, revert the Darktable apt sources."
          changeAptSource "/etc/apt/sources.list.d/pmjdebruijn-ubuntu-darktable-release-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
          repoUpdate
        elif [[ "$distReleaseName" =~ ^("$stableReleaseName"|"$betaReleaseName")$ ]]; then
          log_warning "No new repo, revert the Darktable apt sources."
          println_red "No new repo, revert the Darktable apt sources."
          changeAptSource "/etc/apt/sources.list.d/pmjdebruijn-ubuntu-darktable-release-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
          repoUpdate
        fi
        sudo apt install -y darktable
      else
        sudo apt install -y darktable
      fi
    fi
  else
    sudo apt install -y darktable
  fi
}

rapidPhotoDownloaderInstall() {
  # Rapid Photo downloader
  log_info "Rapid Photo downloader"
  println_blue "Rapid Photo downloader"
  wget -P "$HOME/tmp" https://launchpad.net/rapid/pyqt/0.9.4/+download/install.py
  cd "$HOME/tmp" || return
  python3 install.py
  cd "$currentPath" || return
}

# #########################################################################
# Install photo applications
photoAppsInstall () {
  log_info "Photo Apps install"
  println_blue "Photo Apps install                                                   "
  # digikamInstall
  # darktableInstall
  # rapidPhotoDownloaderInstall
  sudo apt install -y rawtherapee graphicsmagick imagemagick ufraw;
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O           General Apps Install                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# #########################################################################
# changeAptSource
changeAptSource () {

  infile=$1			#File name of current apt
  oldrelease=$2		#distro release of current apt - typically in the filename, precise, natty, ...
  newrelease=$3		#distro of new release

  log_info "Change Apt Source $infile from $oldrelease to $newrelease"
  # log_info "Infile=$infile"
  # log_debug "Old Release=$oldrelease"
  # log_debug "New Release=$newrelease"


  outfile=${infile/$oldrelease/$newrelease}
  # log_debug "Outfile=$outfile"

  sudo cp "$infile" "$outfile"

  sudo sed -i.save -e "s/$oldrelease/$newrelease/" "$outfile"

  sudo sed -i.save -e "s/deb/#deb/" "$infile"
}

flatpakInstall() {
  # Flatpak Install and Setup
  log_info "Flatpak Install and Setup"
  println_blue "Flatpak Install and Setup"
  # Use Flatpak from the Universe Repo and not from the latest PPA
  # sudo add-apt-repository -y ppa:alexlarsson/flatpak
  # if [[ $betaAns == 1 ]]; then
  #   log_warning "Beta Code, revert the Flatpak apt sources."
  #   println_red "Beta Code, revert the Flatpak apt sources."
  #   changeAptSource "/etc/apt/sources.list.d/alexlarsson-ubuntu-flatpak-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  #   repoUpdate
  # elif [[ $noCurrentReleaseRepo == 1 ]]; then
  #   log_warning "No new repo, revert the Flatpak apt sources."
  #   println_red "No new repo, revert the Flatpak apt sources."
  #   changeAptSource "/etc/apt/sources.list.d/alexlarsson-ubuntu-flatpak-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  #   repoUpdate
  # fi
  sudo apt install -y flatpak
  sudo apt install -y gnome-software-plugin-flatpak
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  sudo flatpak remote-add --if-not-exists kdeapps --from https://distribute.kde.org/kdeapps.flatpakrepo
  sudo flatpak install -y kdeapps org.kde.okular
  sudo flatpak install -y flathub org.kde.Platform//5.9
  sudo flatpak install -y flathub org.kde.Sdk//5.9
  # Add support for Gnome in form of adwaita icons and adwaita-qt style
  sudo flatpak install -y kdeapps org.freedesktop.Platform.Icontheme.Adwaita
  sudo flatpak install -y kdeapps org.kde.KStyle.Adwaita
  sudo flatpak install -y kdeapps org.kde.PlatformTheme.QGnomePlatform
}

# ############################################################################
# Install Base applications
installBaseApps () {
  log_info "Start installation of the base utilities and apps"
  println_banner_yellow "Start installation of the base utilities and apps                    "

	sudo apt install -yf gparted nfs-kernel-server nfs-common samba ssh sshfs rar gawk vim vim-doc tree meld htop iptstate kerneltop vnstat nmon qpdfview terminator autofs default-jdk default-jdk-doc default-jdk-headless default-jre default-jre-headless dnsutils net-tools network-manager-openconnect network-manager-vpnc network-manager-ssh network-manager-vpnc network-manager-ssh network-manager-pptp openssl xdotool openconnect flatpak traceroute gcc make zsync
  # Removed for 19.10+
  sudo apt install bzr vim-gnome

  # Add
  # openjdk-11-jdk openjdk-11-jre

  # Add JAVA_HOME to .bash_profile
  # Add JAVA_HOME to .bash_profile
  if [[ ! -f $HOME/.bash_profile ]]; then
    touch "$HOME/.bash_profile"
    chmod +x "$HOME/.bash_profile"
  fi
  sed -i -e 'export JAVA_HOME="/usr/lib/jvm/default-java"' "$HOME/.bash_profile"
  # sed -i -e "export JAVA_HOME="$(jrunscript -e 'java.lang.System.out.println(java.lang.System.getProperty("java.home"));')"" $HOME/.bash_profile
  source "/etc/environment"
  echo "$JAVA_HOME"


	# desktop specific applications
	case $desktopEnvironment in
		"kde" )
			sudo apt install -y kubuntu-restricted-addons kubuntu-restricted-extras kfind
			;;
		"gnome" )
			sudo apt install -y gmountiso dconf-tools ubuntu-restricted-extras gnome-tweak-tool
			;;
		"ubuntu" )
			sudo apt install -y gmountiso dconf-tools ubuntu-restricted-extras gnome-tweak-tool
			;;
		"xubuntu" )
			sudo apt install -y gmountiso;
			;;
		"lubuntu" )
			sudo apt install -y gmountiso;
			;;
	esac
  # doublecmdInstall
  # webupd8AppsInstall
  # yppaManagerInstall
}

# ############################################################################
# Install applications
installUniverseApps () {
  log_info "Start Applications installation the general apps"
  println_banner_yellow "Start Applications installation the general apps                     "
  sudo add-apt-repository -y universe

  log_info "UGet Integrator"
  println_blue "UGet Integrator"
  sudo add-apt-repository -y ppa:uget-team/ppa
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the UGet Integrator apt sources."
    println_red "Beta Code, revert the UGet Integrator apt sources."
    changeAptSource "/etc/apt/sources.list.d/uget-team-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  elif [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the UGet Integrator apt sources."
    println_red "No new repo, revert the UGet Integrator apt sources."
    changeAptSource "/etc/apt/sources.list.d/uget-team-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi

	# general applications
  sudo apt install -yf
	sudo apt install -yf synaptic aptitude mc filezilla remmina rdiff-backup luckybackup printer-driver-cups-pdf keepassx flashplugin-installer ffmpeg keepnote workrave unison unison-gtk deluge-torrent liferea planner chromium-browser blender caffeine gufw cockpit thunderbird uget uget-integrator glance

  # Older packages...
  # Still active, but replaced with other apps
  # unetbootin = etcher


  # older packages that will not install on new releases
  if ! [[ "$distReleaseName" =~ ^(yakkety|zesty|artful|bionic|cosmic|disco|eaon)$ ]]; then
   sudo apt install -yf scribes cnijfilter-common-64 cnijfilter-mx710series-64 scangearmp-common-64 scangearmp-mx710series-64
  fi
  if ! [[ "$distReleaseName" =~ ^(bionic|cosmic|disco|eoan)$ ]]; then
   sudo apt install -yf shutter
  fi
	# desktop specific applications
	case $desktopEnvironment in
		"kde" )
			sudo apt install -y kubuntu-restricted-addons kubuntu-restricted-extras kdf k4dirstat filelight kde-config-cron kdesdk-dolphin-plugins libqt4-sql-psql libqt4-sql-sqlite libterm-readline-gnu-perl libterm-readline-perl-perl djvulibre-bin finger hspell sg3-utils;
      latteDockInstall
      # Old packages:
      # ufw-kde amarok amarok-doc moodbar kcron
			;;
		"gnome" )
			sudo apt install -y gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky nautilus-image-converter wallch alacarte gnome-shell-extensions-gpaste
      sudo apt install -y ambiance-colors radiance-colors;
			;;
		"ubuntu" )
      sudo apt install -y gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky nautilus-image-converter wallch alacarte gnome-shell-extensions-gpaste ambiance-colors radiance-colors;
			;;
		"xubuntu" )
			sudo apt install -y gmountiso gnome-commander;
			;;
		"lubuntu" )
			sudo apt install -y gmountiso gnome-commander;
			;;
	esac
  # doublecmdInstall
  # webupd8AppsInstall
  # yppaManagerInstall
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O           Menus                                                          O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# ############################################################################
# Set Ubuntu Version Parameters
setUbuntuVersionParameters() {
  # read -rp "Do you want to setup the build for a beta install? (y/n) " answer
  if [[ $answer = [Yy1] ]]; then
    betaAns=1
    validchoice=0
    until [[ $validchoice == 1 ]]; do
      clear
      printf "\\n\\n\\n"
      println_yellow "Running $desktopEnvironment $distReleaseName $distReleaseVer"
      printf "
      There are the following options for selecting a stable release for the repositories
           that are known for not having beta or early releases:
      Key  : Stable Release
      -----: ---------------------------------------
      e    : 19.10 Eoan Ermine
      d    : 19.04 Disco Dingo
      c    : 18.10 Cosmic Cuttlefish
      b    : 18.04 Bionic Beaver
      a    : 17.10 Artful Aardvark
      x    : 17.04 Zesty
      y    : 16.10 Yakkety
      x    : 16.04 Xenial LTS
      w    : 15.10 Wily
      v    : 15.04 Vivid
      u    : 14.10 Utopic
      t    : 14.04 Trusty LTS
      s    : 13.10 Saucy
      r    : 13.04 Raring
      q    : 12.10 Quantal
      p    : 12.04 Precise LTS
      o    : 11.10 Oneiric
      n    : 11.04 Natty
      m    : 10.10 Maverick
      l    : 10.04 Lucid LTS

      quit : Quit this selection

      "

      read -rp "Enter your choice : " stablechoice
      printf "\\n"
      case $stablechoice in
        e)
          stableReleaseName="disco"
          stableReleaseVer="18.10"
          betaReleaseName="eoan"
          betaReleaseVer="19.10"
          previousStableReleaseName="cosmic"
          validchoice=1
        ;;
        d)
          stableReleaseName="disco"
          stableReleaseVer="19.04"
          betaReleaseName="eoan"
          betaReleaseVer="19.10"
          previousStableReleaseName="cosmic"
          validchoice=1
        ;;
        c)
          stableReleaseName="cosmic"
          stableReleaseVer="18.10"
          betaReleaseName="disco"
          betaReleaseVer="19.04"
          previousStableReleaseName="bionic"
          validchoice=1
        ;;
        b)
          stableReleaseName="bionic"
          stableReleaseVer="18.04"
          betaReleaseName="cosmic"
          betaReleaseVer="18.10"
          previousStableReleaseName="artful"
          validchoice=1
        ;;
        a )
          stableReleaseName="artful"
          stableReleaseVer="17.10"
          betaReleaseName="bionic"
          betaReleaseVer="18.04"
          previousStableReleaseName="zesty"
          validchoice=1
        ;;
        z )
          stableReleaseName="zesty"
          stableReleaseVer="17.04"
          betaReleaseName="artful"
          betaReleaseVer="17.10"
          previousStableReleaseName="yakkety"
          validchoice=1
        ;;
        y )
          stableReleaseName="yakkety"
          stableReleaseVer="16.10"
          validchoice=1
        ;;
        x )
          stableReleaseName="xenial"
          stableReleaseVer="16.04"
          validchoice=1
        ;;
        w )
          stableReleaseName="wily"
          stableReleaseVer="15.10"
          validchoice=1
        ;;
        v )
          stableReleaseName="vivid"
          stableReleaseVer="15.04"
          validchoice=1
        ;;
        u )
          stableReleaseName="utopic"
          stableReleaseVer="14.10"
          validchoice=1
        ;;
        t )
          stableReleaseName="trusty"
          stableReleaseVer="14.04"
          validchoice=1
        ;;
        s )
          stableReleaseName="saucy"
          stableReleaseVer="13.10"
          validchoice=1
        ;;
        r )
          stableReleaseName="raring"
          stableReleaseVer="13.04"
          validchoice=1
        ;;
        q )
          stableReleaseName="quantal"
          stableReleaseVer="12.10"
          validchoice=1
        ;;
        p )
          stableReleaseName="precise"
          stableReleaseVer="12.04"
          validchoice=1
        ;;
        o )
          stableReleaseName="oneiric"
          stableReleaseVer="11.10"
          validchoice=1
        ;;
        n )
          stableReleaseName="natty"
          stableReleaseVer="11.04"
          validchoice=1
        ;;
        m )
          stableReleaseName="maverick"
          stableReleaseVer="10.10"
          validchoice=1
        ;;
        l )
          stableReleaseName="lucid"
          stableReleaseVer="10.04"
          validchoice=1
        ;;
        quit|0)
          validchoice=1
        ;;
        * )
          printf "Please enter a valid choice, the first letter of the stable release you need."
          validchoice=0
        ;;
      esac
    done
  fi
}

# ############################################################################
# Preselect menu options, display menu and then install as per the main menu option
menuRun() {
  local choiceOpt
  local typeOfRun=$1
  shift
  local menuSelections=("$@")

  selectionMenu(){

    menuSelectionsInput=(
      1     #: Run Selection

      111   #: Kernel upgrade
      112   #: Repositories update
      113   #: Repositories upgrade
      114   #: Repository Key Check
      121   #: Install additional basic utilties and applications
      122   #: Install my selection of Universe applications
      125   #: Install and configure Flatpak
      131   #: Setup the home directories to link to the data disk directories
      141   #: Install KDE Desktop from backports
      142   #: Upgrae KDE to Beta KDE on backports
      143   #: KDE Desktop settings
      #: kde-plasma-desktop
      151   #: Install Gnome Desktop from backports
      152   #: Gnome Settings
      #: sudo apt install gnome-session / sudo update-alternatives --config gdm3.css
      #: ubuntu-desktop
      #: ubuntu-desktop-minimal
      #: ubuntu-gnome-desktop
      #: ubuntu-budgie-desktop
      #: ubuntustudio-installer
      161   #: ownCloudClient
      162   #: Dropbox
      163   #: inSync for GoogleDrive

            #: submenuUtils
      211   #: Latte Dock
      212   #: Doublecmd
      213   #: FreeFileSync
      221   #: Powerline
      222   #: Bleachbit
      231   #: Bitwarden Password Manager
      241   #: Stacer Linux system info and cleaner
      251   #: Etcher USB Loader
      252   #: UNetbootin
      271   #: Y-PPA Manager
      272   #: bootRepair
      #: tasksel
      281   #: rEFInd Boot Manager
      282   #: Battery Manager
      291   #: Install extra fonts
      292   #: Install cheat the cheatsheet for the commandline

            #: submenuInternet
      311   #: Google Chrome browser
      312   #: Opera browser
      321   #: Thunderbird email
      323   #: Mailspring desktop email client
      324   #: Evolution email
      331   #: Skype
      332   #: Slack
      341   #: Winds RSS Reader and Podcast application
      342   #: Tusk Evernote application
      351   #: Xtreme Download Manager

            #: submenuApps
      421   #: Favorite Book Reader
      441   #: Calibre
      442   #: KMyMoney
      451   #: Anbox - Android Box
      461   #: LibreCAD

            #: submenuDev
      511   #: Install Development Apps and IDEs
      512   #: Git
      513   #: Atom Editor
      514   #: Brackets Editor
      521   #: Bashdb
      522   #: PyCharm
      523   #: Eclipse IDE
      524   #: Visual Studio Code
      525   #: Intellij Idea Community
      531   #: Postman
      541   #: AsciiDoc
      581   #: OpenJDK Latest
      582   #: OpenJDK 8
      583   #: OpenJDK 11
      585   #: Oracle Java Latest
      586   #: Oracle Java 8
      587   #: Oracle Java 11
      588   #: Set Java Version
      591   #: Git Config with my details
      595   #: Add Ruby Repositories

            #: submenuPhoto
      611   #: Photography Apps
      612   #: Variety
      621   #: Digikam
      622   #: Darktable
      631   #: RapidPhotoDownloader
      641   #: Image Editing Applications
      651   #: Inkscape

            #: submenuMedia
      711   #: Music and Video Applications
      712   #: Google Play Music Desktop Player
      713   #: Spotify
      721   #: Kodi

            #: submenuVirtualization
      811   #: Docker
      821   #: Setup for a VirtualBox guest
      822   #: VirtualBox Host
      831   #: Setup for a Vmware guest
      851   #: Vagrant
      881   #: KVM

            #: submenuOther
      911   #: OpenVPN install
      921   #: Laptop Display Drivers for Intel en Nvidia
      923   #: DisplayLink

            #: submenuSettings
      2     #: Toggle No Questions asked
      3     #: Toggle noCurrentReleaseRepo
      191   #: Create test data directories on data drive.
      192   #: Set options for an Ubuntu Beta install with PPA references to a previous version.
    )

    clear
    printf "\\n\\n"
    case $typeOfRun in
    SelectThenAutoRun )
      printf "  %s%sSelect items and then install the items without prompting.%s\\n" "${rev}" "${bold}" "${normal}"
    ;;
    SelectThenStepRun )
      printf "  %s%sSelect items and then install the items each with a prompt.%s\\n" "${rev}" "${bold}"  "${normal}"
    ;;
    SelectItem )
      printf "  %s%sSelect items and for individual installation with prompt.%s\\n" "${rev}" "${bold}" "${normal}"
    esac
    printf "
    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "111" ]]; then printf "%s%s111%s" "${rev}" "${bold}" "${normal}"; else printf "111"; fi; printf "  : Kernel upgrade.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "112" ]]; then printf "%s%s112%s" "${rev}" "${bold}" "${normal}"; else printf "112"; fi; printf "  : Repositories update.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "113" ]]; then printf "%s%s113%s" "${rev}" "${bold}" "${normal}"; else printf "113"; fi; printf "  : Repositories upgrade.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "114" ]]; then printf "%s%s114%s" "${rev}" "${bold}" "${normal}"; else printf "114"; fi; printf "  : Repository Key Check.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "121" ]]; then printf "%s%s121%s" "${rev}" "${bold}" "${normal}"; else printf "121"; fi; printf "  : Install the base utilites and applications.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "122" ]]; then printf "%s%s122%s" "${rev}" "${bold}" "${normal}"; else printf "122"; fi; printf "  : Install all my Universe application.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "125" ]]; then printf "%s%s125%s" "${rev}" "${bold}" "${normal}"; else printf "125"; fi; printf "  : Flatpak install and configure.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "131" ]]; then printf "%s%s131%s" "${rev}" "${bold}" "${normal}"; else printf "131"; fi; printf "  : Setup the home directories to link to the data disk directories.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "141" ]]; then printf "%s%s141%s" "${rev}" "${bold}" "${normal}"; else printf "141"; fi; printf "  : Install KDE Desktop from backports.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "142" ]]; then printf "%s%s142%s" "${rev}" "${bold}" "${normal}"; else printf "142"; fi; printf "  : Upgrade KDE to Beta KDE on backports.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "143" ]]; then printf "%s%s143%s" "${rev}" "${bold}" "${normal}"; else printf "143"; fi; printf "  : Change KDE desktop settings.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "151" ]]; then printf "%s%s151%s" "${rev}" "${bold}" "${normal}"; else printf "151"; fi; printf "  : Install Gnome Desktop from backports.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "152" ]]; then printf "%s%s152%s" "${rev}" "${bold}" "${normal}"; else printf "152"; fi; printf "  : Change Gnome desktop settings.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "161" ]]; then printf "%s%s161%s" "${rev}" "${bold}" "${normal}"; else printf "161"; fi; printf "  : ownCloudClient.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "162" ]]; then printf "%s%s162%s" "${rev}" "${bold}" "${normal}"; else printf "162"; fi; printf "  : Dropbox.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "163" ]]; then printf "%s%s163%s" "${rev}" "${bold}" "${normal}"; else printf "163"; fi; printf "  : inSync for GoogleDrive.\\n"
    printf "\\n"
    printf "     a    : Utilities Menu.\\n"
    printf "     b    : Internet and eMail Menu.\\n"
    printf "     c    : Applications Menu.\\n"
    printf "     d    : Development Apps and IDEs Menu.\\n"
    printf "     e    : Photography and Imaging Menu.\\n"
    printf "     f    : Multimedia, Video and Audio Menu.\\n"
    printf "     g    : Virtualization Applictions Menu.\\n"
    printf "     h    : Other (Hardware Drivers, ).\\n"
    printf "     i    : Buildman Settings, Utilities and tests.\\n"
    printf "     x    : Clear selections.\\n"
    printf "\\n"
    printf "\\n"
    printf "     %s1   : RUN%s\\n" "${bold}" "${normal}"
    printf "\\n"
    printf "     0/q   : Return to main menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuUtils(){
    clear
    printf "\\n\\n"
    printf "  %s%sUtilities%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "211" ]]; then printf "%s%s211%s" "${rev}" "${bold}" "${normal}"; else printf "211"; fi; printf "  : Latte Dock.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "212" ]]; then printf "%s%s212%s" "${rev}" "${bold}" "${normal}"; else printf "212"; fi; printf "  : Doublecmd.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "213" ]]; then printf "%s%s213%s" "${rev}" "${bold}" "${normal}"; else printf "213"; fi; printf "  : FreeFileSync.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "221" ]]; then printf "%s%s221%s" "${rev}" "${bold}" "${normal}"; else printf "221"; fi; printf "  : Powerline.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "222" ]]; then printf "%s%s222%s" "${rev}" "${bold}" "${normal}"; else printf "222"; fi; printf "  : Bleachbit.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "231" ]]; then printf "%s%s231%s" "${rev}" "${bold}" "${normal}"; else printf "231"; fi; printf "  : Bitwarden Password Manager.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "241" ]]; then printf "%s%s241%s" "${rev}" "${bold}" "${normal}"; else printf "241"; fi; printf "  : Stacer Linux System Optimizer and Monitoring.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "251" ]]; then printf "%s%s251%s" "${rev}" "${bold}" "${normal}"; else printf "251"; fi; printf "  : Etcher USB loader.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "252" ]]; then printf "%s%s252%s" "${rev}" "${bold}" "${normal}"; else printf "252"; fi; printf "  : UNetbootin ISO to USB Application.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "271" ]]; then printf "%s%s271%s" "${rev}" "${bold}" "${normal}"; else printf "271"; fi; printf "  : Y-PPA Manager.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "272" ]]; then printf "%s%s272%s" "${rev}" "${bold}" "${normal}"; else printf "272"; fi; printf "  : Boot Repair Appliction.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "281" ]]; then printf "%s%s281%s" "${rev}" "${bold}" "${normal}"; else printf "281"; fi; printf "  : rEFInd Boot Manager.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "282" ]]; then printf "%s%s282%s" "${rev}" "${bold}" "${normal}"; else printf "282"; fi; printf "  : Battery Manager.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "291" ]]; then printf "%s%s291%s" "${rev}" "${bold}" "${normal}"; else printf "291"; fi; printf "  : Install extra fonts.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "292" ]]; then printf "%s%s292%s" "${rev}" "${bold}" "${normal}"; else printf "292"; fi; printf "  : Install cheat the cheatsheet for the commandline.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuInternet(){
    clear
    printf "\\n\\n"
    printf "  %s%sInternet and eMail%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "311" ]]; then printf "%s%s311%s" "${rev}" "${bold}" "${normal}"; else printf "311"; fi; printf "  : Google Chrome browser.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "312" ]]; then printf "%s%s312%s" "${rev}" "${bold}" "${normal}"; else printf "312"; fi; printf "  : Opera Browser.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "321" ]]; then printf "%s%s321%s" "${rev}" "${bold}" "${normal}"; else printf "321"; fi; printf "  : Thunderbird email client.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "323" ]]; then printf "%s%s323%s" "${rev}" "${bold}" "${normal}"; else printf "323"; fi; printf "  : Mailspring desktop email client.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "324" ]]; then printf "%s%s324%s" "${rev}" "${bold}" "${normal}"; else printf "324"; fi; printf "  : Evolution email client.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "331" ]]; then printf "%s%s331%s" "${rev}" "${bold}" "${normal}"; else printf "331"; fi; printf "  : Skype.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "332" ]]; then printf "%s%s332%s" "${rev}" "${bold}" "${normal}"; else printf "332"; fi; printf "  : Slack.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "341" ]]; then printf "%s%s341%s" "${rev}" "${bold}" "${normal}"; else printf "341"; fi; printf "  : Winds RSS Reader and Podcast application.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "342" ]]; then printf "%s%s342%s" "${rev}" "${bold}" "${normal}"; else printf "342"; fi; printf "  : Tusk Evernote application.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "351" ]]; then printf "%s%s351%s" "${rev}" "${bold}" "${normal}"; else printf "351"; fi; printf "  : Xtreme Download Manager application.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuApps(){
    clear
    printf "\\n\\n"
    printf "  %s%sApplications%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "421" ]]; then printf "%s%s421%s" "${rev}" "${bold}" "${normal}"; else printf "421"; fi; printf "  : Favorite Book Reader.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "441" ]]; then printf "%s%s441%s" "${rev}" "${bold}" "${normal}"; else printf "441"; fi; printf "  : Calibre.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "442" ]]; then printf "%s%s442%s" "${rev}" "${bold}" "${normal}"; else printf "442"; fi; printf "  : KMyMoney.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "451" ]]; then printf "%s%s451%s" "${rev}" "${bold}" "${normal}"; else printf "451"; fi; printf "  : Anbox.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "461" ]]; then printf "%s%s461%s" "${rev}" "${bold}" "${normal}"; else printf "461"; fi; printf "  : LibreCAD.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuDev(){
    clear
    printf "\\n\\n"
    printf "  %s%sDevelopment applications and IDEs%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "511" ]]; then printf "%s%s511%s" "${rev}" "${bold}" "${normal}"; else printf "511"; fi; printf "  : Install Development Apps and IDEs.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "512" ]]; then printf "%s%s512%s" "${rev}" "${bold}" "${normal}"; else printf "512"; fi; printf "  : Git.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "513" ]]; then printf "%s%s513%s" "${rev}" "${bold}" "${normal}"; else printf "513"; fi; printf "  : Atom Editor.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "514" ]]; then printf "%s%s514%s" "${rev}" "${bold}" "${normal}"; else printf "514"; fi; printf "  : Brackets Editor.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "521" ]]; then printf "%s%s521%s" "${rev}" "${bold}" "${normal}"; else printf "521"; fi; printf "  : Bashdb.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "522" ]]; then printf "%s%s522%s" "${rev}" "${bold}" "${normal}"; else printf "522"; fi; printf "  : PyCharm IDE.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "523" ]]; then printf "%s%s523%s" "${rev}" "${bold}" "${normal}"; else printf "523"; fi; printf "  : Eclipse IDE.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "524" ]]; then printf "%s%s524%s" "${rev}" "${bold}" "${normal}"; else printf "524"; fi; printf "  : Visual Studio Code.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "525" ]]; then printf "%s%s525%s" "${rev}" "${bold}" "${normal}"; else printf "525"; fi; printf "  : Intellij Idea Community.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "531" ]]; then printf "%s%s531%s" "${rev}" "${bold}" "${normal}"; else printf "531"; fi; printf "  : Postman.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "541" ]]; then printf "%s%s541%s" "${rev}" "${bold}" "${normal}"; else printf "541"; fi; printf "  : AsciiDoc.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "585" ]]; then printf "%s%s581%s" "${rev}" "${bold}" "${normal}"; else printf "581"; fi; printf "  : OpenJDK Latest.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "581" ]]; then printf "%s%s582%s" "${rev}" "${bold}" "${normal}"; else printf "582"; fi; printf "  : OpenJDK 8.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "582" ]]; then printf "%s%s583%s" "${rev}" "${bold}" "${normal}"; else printf "583"; fi; printf "  : OpenJDK 11.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "583" ]]; then printf "%s%s585%s" "${rev}" "${bold}" "${normal}"; else printf "585"; fi; printf "  : Oracle Java Latest.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "586" ]]; then printf "%s%s586%s" "${rev}" "${bold}" "${normal}"; else printf "586"; fi; printf "  : Oracle Java 8.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "587" ]]; then printf "%s%s587%s" "${rev}" "${bold}" "${normal}"; else printf "587"; fi; printf "  : Oracle Java 11.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "588" ]]; then printf "%s%s588%s" "${rev}" "${bold}" "${normal}"; else printf "588"; fi; printf "  : Set Java Version.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "590" ]]; then printf "%s%s590%s" "${rev}" "${bold}" "${normal}"; else printf "590"; fi; printf "  : Git Config with my details.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "595" ]]; then printf "%s%s595%s" "${rev}" "${bold}" "${normal}"; else printf "595"; fi; printf "  : Ruby Repo.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuPhoto(){
    clear
    printf "\\n\\n"
    printf "  %s%sPhoto and Imaging Applications%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "611" ]]; then printf "%s%s611%s" "${rev}" "${bold}" "${normal}"; else printf "611"; fi; printf "  : Photography Apps.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "612" ]]; then printf "%s%s612%s" "${rev}" "${bold}" "${normal}"; else printf "612"; fi; printf "  : Variety.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "621" ]]; then printf "%s%s621%s" "${rev}" "${bold}" "${normal}"; else printf "621"; fi; printf "  : Digikam.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "622" ]]; then printf "%s%s622%s" "${rev}" "${bold}" "${normal}"; else printf "622"; fi; printf "  : Darktable.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "631" ]]; then printf "%s%s631%s" "${rev}" "${bold}" "${normal}"; else printf "631"; fi; printf "  : RapidPhotoDownloader.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "641" ]]; then printf "%s%s641%s" "${rev}" "${bold}" "${normal}"; else printf "641"; fi; printf "  : Image Editing Applications.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "651" ]]; then printf "%s%s651%s" "${rev}" "${bold}" "${normal}"; else printf "651"; fi; printf "  : Inkscape.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuMedia(){
    clear
    printf "\\n\\n"
    printf "  %s%sAudio, Video and Media Applications%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "711" ]]; then printf "%s%s711%s" "${rev}" "${bold}" "${normal}"; else printf "711"; fi; printf "  : Music and Video Applications.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "713" ]]; then printf "%s%s713%s" "${rev}" "${bold}" "${normal}"; else printf "713"; fi; printf "  : Spotify.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "712" ]]; then printf "%s%s712%s" "${rev}" "${bold}" "${normal}"; else printf "712"; fi; printf "  : Google Play Music Desktop Player.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "721" ]]; then printf "%s%s721%s" "${rev}" "${bold}" "${normal}"; else printf "721"; fi; printf "  : Kodi media center.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuVirtualization(){
    clear
    printf "\\n\\n"
    printf "  %s%sVirtualization%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "811" ]]; then printf "%s%s811%s" "${rev}" "${bold}" "${normal}"; else printf "811"; fi; printf "  : Docker.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "821" ]]; then printf "%s%s821%s" "${rev}" "${bold}" "${normal}"; else printf "821"; fi; printf "  : Setup for a VirtualBox guest.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "822" ]]; then printf "%s%s822%s" "${rev}" "${bold}" "${normal}"; else printf "822"; fi; printf "  : VirtualBox Host.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "831" ]]; then printf "%s%s831%s" "${rev}" "${bold}" "${normal}"; else printf "831"; fi; printf "  : Setup for a Vmware guest.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "851" ]]; then printf "%s%s851%s" "${rev}" "${bold}" "${normal}"; else printf "851"; fi; printf "  : Vagrant.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "881" ]]; then printf "%s%s881%s" "${rev}" "${bold}" "${normal}"; else printf "881"; fi; printf "  : KVM.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuOther(){
    clear
    printf "\\n\\n"
    printf "  %s%sHardware Drivers%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "911" ]]; then printf "%s%s911%s" "${rev}" "${bold}" "${normal}"; else printf "911"; fi; printf "  : OpenVPN Install.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "921" ]]; then printf "%s%s921%s" "${rev}" "${bold}" "${normal}"; else printf "921"; fi; printf "  : Laptop Display Drivers for Intel en Nvidia.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "923" ]]; then printf "%s%s923%s" "${rev}" "${bold}" "${normal}"; else printf "923"; fi; printf "  : DisplayLink.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  submenuSettings(){
    clear
    printf "\\n\\n"
    printf "  %s%sBuildman Settings%s\\n\\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "2" ]]; then printf "%s%s2%s" "${rev}" "${bold}" "${normal}"; else printf "2"; fi; printf "   : Questions asked is "; if [[ "$noPrompt" = 1 ]]; then printf "%s%sOFF%s" "${rev}" "${bold}" "${normal}"; else printf "%s%sON%s" "${rev}" "$bold" "$normal"; fi; printf ". Select 2 to toggle so that questions is "; if [[ "$noPrompt" = 1 ]]; then printf "%sASKED%s" "${bold}" "${normal}"; else printf "%sNOT ASKED%s" "${bold}" "${normal}"; fi; printf ".\\n";
    printf "     ";if [[ "${menuSelections[*]}" =~ "3" ]]; then printf "%s%s3%s" "${rev}" "${bold}" "${normal}"; else printf "3"; fi; printf "   : noCurrentReleaseRepo is "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%s%sON%s" "${rev}" "${bold}" "${normal}"; else printf "%sOFF%s" "$bold" "$normal"; fi; printf ". Select 3 to toggle noCurrentReleaseRepo to "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%sOFF%s" "${bold}" "${normal}"; else printf "%sON%s" "${bold}" "${normal}"; fi; printf ".\\n";
    printf "     ";if [[ "${menuSelections[*]}" =~ "191" ]]; then printf "%s%s191%s" "${rev}" "${bold}" "${normal}"; else printf "191"; fi; printf " : Create test data directories on data drive.\\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "192" ]]; then printf "%s%s192%s" "${rev}" "${bold}" "${normal}"; else printf "192"; fi; printf " : Set options for an Ubuntu Beta install with PPA references to a previous version.\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\\n\\n"
    fi
  }

  howToRun() {
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
    printf "\\n"
    if ((1<choiceOpt && choiceOpt<=999))
    then
      howToRun "$choiceOpt" "$typeOfRun"
    elif ((choiceOpt==1))
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
            submenuUtils "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((200<=choiceOpt && choiceOpt<=299))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        b )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuInternet "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((300<=choiceOpt && choiceOpt<=399))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        c )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuApps "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((400<=choiceOpt && choiceOpt<=499))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        d )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuDev "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((500<=choiceOpt && choiceOpt<=599))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        e )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuPhoto "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((600<=choiceOpt && choiceOpt<=699))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        f )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuMedia "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((700<=choiceOpt && choiceOpt<=799))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        g )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuVirtualization "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((800<=choiceOpt && choiceOpt<=899))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        h )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuOther "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((900<=choiceOpt && choiceOpt<=999))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        i )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuSettings "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\\n"
            if ((2<=choiceOpt && choiceOpt<=199)); then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        x )
          menuSelections=()
        ;;
      esac
    fi
  done
}

runSelection() {
  # take inputs and perform as necessary
  case $1 in
    111 ) asking kernelUprade "do a Kernel Upgrade" "Kernel Upgrade Complete." ;;
    112 ) asking repoUpdate "do a Repository Update" "Repository Update Complete." ;;
    113 ) asking repoUpgrade "do a Repository Upgrade" "Repository Upgrade Complete." ;;
    114 ) asking ppaKeyCheck "do a Repository Key Check" "Repository Key Check Complete." ;;
    121 ) asking installBaseApps "Install the base utilities and applications" "Base Utilities and applications install complete." ;;
    122 ) asking installUniverseApps "Install all my Universe applications" "Universe applications install complete." ;;
    125 ) asking flatpakInstall "Install Flatpak and configure Flatpak Repos" "Flatpak Install and Flatpak Repos Complete." ;;
    131 ) asking dataDirLinksSetup "Setup the home directories to link to the data disk directories" "Setup of the home directories to link to the data disk directories complete." ;;
    191 ) asking createTestDataDirs "Create test data directories on data drive." "Test data directories on data drive created." ;;
    141 ) asking kdeBackportsApps "Install KDE Desktop from backports" "Installation of the KDE Backport Desktop complete." ;;
    142 ) asking kdeBetaBackportsRepo "Upgrae KDE repo to Beta KDE Repo on backports" "Upgrae of the KDE Beta repo complete." ;;
    143 ) asking kde5Settings "run KDE Desktop settings" "KDE Desktop Settings done." ;;
    151 ) asking gnome3Backports "Install Gnome Desktop from backports" "Gnome Desktop install from backports complete." ;;
    152 ) asking gnome3Settings "run Gnome settings" "Gnome Settings done." ;;
    161 ) asking ownCloudClientInstallApp "install ownCloud client" "ownCloud Client install complete." ;;
    162 ) asking dropboxInstall "install Dropbox"  "Dropbox install complete." ;;
    163 ) asking insyncInstall  "install inSync for GoogleDrive" "inSync for GoogleDrive install complete." ;;
    192 ) asking setUbuntuVersionParameters "Set options for an Ubuntu Beta install with PPA references to another version." "Set Ubuntu Version Complete" ;;
    212 ) asking  doublecmdInstall "Install Doublecmd" "Doublecmd install complete." ;;
    211 ) asking latteDockInstall "Install Latte Dock" "Latte Dock install complete." ;;
    213 ) asking FreeFileSyncInstall "install FreeFileSync" "FreeFileSync install complete." ;;
    221 ) asking powerlineInstall "install Powerline" "Powerline install complete." ;;
    222 ) asking bleachbitInstall "install Bleachbit" "Bleachbit install complete." ;;
    231 ) asking bitwardenInstall "install Bitwarden Password Manager" "Bitwarden Password Manager install complete." ;;
    241 ) asking stacerInstall "install Stacer Linux System Optimizer and Monitoring" "Stacer Linux System Optimizer and Monitoring install complete." ;;
    251 ) asking etcherInstall "install Etcher USB Loader" "Etcher USB Loader install complete." ;;
    252 ) asking unetbootinInstall "install UNetbootin" "UNetbootin install complete." ;;
    271 ) asking yppaManagerInstall "install Y-PPA Manager" "Y-PPA Manager install complete." ;;
    272 ) asking bootRepairInstall "install Boot Repair" "Boot Repair install complete." ;;
    281 ) asking rEFIndInstall "install rEFInd Boot Manager" "rEFInd Boot Manager install complete." ;;
    282 ) asking batteryManagerInstall "install Battery Manager" "Battery Manager install complete." ;;
    291 ) asking fontsInstall "install extra fonts" "Extra fonts install complete." ;;
    292 ) asking cliCheatsheetInstall "install cheat the command line cheatsheet" "Cheat command line cheatsheet install complete." ;;
    311 ) asking googleChromeInstall "Install Google Chrome browser" "Google Chrome browser install complete." ;;
    312 ) asking operaInstall "install Opera browser" "Opera browser install complete." ;;
    321 ) asking thunderbirdInstall  "install Thunderbird email client" "Thunderbird email client install complete." ;;
    323 ) asking mailspringInstall  "install Mailspring desktop email client" "Mailspring desktop email client install complete." ;;
    324 ) asking evolutionInstall  "install Evolution email client" "Evolution email client install complete." ;;
    331 ) asking skypeInstall  "install Skype" "Skype install complete." ;;
    332 ) asking slackInstall  "install Slack" "Slack install complete." ;;
    341 ) asking windsInstall  "install Winds RSS Reader and Podcast application" "Winds RSS Reader and Podcast application install complete." ;;
    342 ) asking tuskInstall  "install Tusk Evernote application" "Tusk Evernote application install complete." ;;
    351 ) asking xdmanInstall  "install Xtreme Download Manager application" "Xtreme Download Manager application install complete." ;;
    421 ) asking fbReaderInstall "install Favorite Book Reader" "Favorite Book Reader install complete." ;;
    441 ) asking calibreInstall "install Calibre" "Calibre install complete." ;;
    442 ) asking kMyMoneyInstall "install KMyMoney" "KMyMoney install complete." ;;
    451 ) asking anboxInstall "install Anbox" "Anbox install complete." ;;
    461 ) asking librecadInstall "instal LibreCAD" "LibreCAD install complete." ;;
    511 ) asking devAppsInstall "install Development Apps and IDEs" "Development Apps and IDEs install complete." ;;
    512 ) asking gitInstall "install Git" "Git install complete." ;;
    513 ) asking atomInstall "Install Atom Editor" "Atom Editor install complete." ;;
    514 ) asking bracketsInstall "Install Brackets Editor" "Brackets Editor install complete." ;;
    521 ) asking bashdbInstall "install Bashdb" "Bashdb install complete." ;;
    522 ) asking pycharmInstall "Install PyCharm" "PyCharm install complete." ;;
    523 ) asking eclipseInstall "Install Eclipse IDE" "Eclipse IDE install complete." ;;
    524 ) asking vscodeInstall "Install Visual Studio Code" "Visual Studio Code install complete." ;;
    525 ) asking intelij-idea-communityInstall "Install Intellij Idea Community" "Intellij Idea Community install complete." ;;
    531 ) asking postmanInstall "Install Postman" "Postman install complete." ;;
    541 ) asking asciiDocInstall "install AsciiDoc" "AsciiDoc install complete." ;;
    581 ) asking openJDKLatestInstall "Install OpenJDK Latest" "OpenJDK Latest install complete." ;;
    582 ) asking openJDK8Install "Install OpenJDK 8" "OpenJDK 8 install complete." ;;
    583 ) asking openJDK11Install "Install OpenJDK 11" "OpenJDK 11 install complete." ;;
    585 ) asking oracleJavaLatestInstall "Install Oracle Java Latest" "Oracle Java Latest install complete." ;;
    586 ) asking oracleJava8Install "Install Oracle Java 8" "Oracle Java 8 install complete." ;;
    587 ) asking oracleJava11Install "Install Oracle Java 11" "Oracle Java 11 install complete." ;;
    588 ) asking setJavaVersion "Set Java Version" "Set Java Version complete." ;;
    590 ) asking gitConfig "Git Config with my details." "Git Config with my details complete." ;;
    595 ) asking rubyRepo "add the Ruby Repositories" "Ruby Repositories added." ;;
    611 ) asking photoAppsInstall "install Photography Apps" "Photography Apps install complete." ;;
    621 ) asking digikamInstall "install Digikam" "DigiKam install complete." ;;
    622 ) asking darktableInstall "install Darktable" "Darktable install complete." ;;
    631 ) asking rapidPhotoDownloaderInstall "install rapidPhotoDownloader" "rapidPhotoDownloader install complete." ;;
    641 ) asking imageEditingAppsInstall  "install Image Editing Applications" "Image Editing Applications installed." ;;
    711 ) asking musicVideoAppsInstall "install Music and Video Applications" "Music and Video Applications installed." ;;
    712 ) asking google-play-music-desktop-playerInstall "install Google Play Music Desktop Player" "Google Play Music Desktop Player installed." ;;
    713 ) asking spotifyInstall "install Spotify" "Spotify installed." ;;
    721 ) asking kodiInstall "install Kodi media center" "Kodi media center installed." ;;
    612 ) asking varietyInstall "install Variety" "Variety installed." ;;
    651 ) asking inkscapeInstall "install Inkscape" "Inkscape installed." ;;
    811 ) asking dockerInstall "install Docker" "Docker install complete." ;;
    821 ) asking virtualboxGuestSetup "Setup and install VirtualBox guest" "VirtaulBox Guest install complete." ;;
    822 ) asking virtualboxHostInstall "Install VirtualBox Host" "VirtualBox Host install complete." ;;
    831 ) asking vmwareGuestSetup "Setup for a Vmware guest" "Vmware Guest setup complete." ;;
    851 ) asking vagrantInstall "install Vagrant" "Vagrant install complete." ;;
    881 ) asking kvmInstall "install KVM" "KVM install complete." ;;
    911 ) asking openvpnInstall "install OpenVPN" "OpenVPN install complete." ;;
    921 ) asking laptopDisplayDrivers "Laptop Display Drivers for Intel en Nvidia" "Laptop Display Drivers for Intel en Nvidia install complete." ;;
    923 ) asking displayLinkInstallApp "install DisplayLink" "DisplayLink install complete." ;;
    2)
      if [[ $noPrompt = 0 ]]; then
        noPrompt=1
        println_blue "Questions asked is OFF.\\n No questions will be asked."
        log_debug "Questions asked is OFF.\\n No questions will be asked."
      else
        noPrompt=0
        println_blue "Questions asked is ON.\\n All questions will be asked."
        log_debug "Questions asked is ON.\\n All questions will be asked."
      fi
    ;;
    3)
      if [[ $noCurrentReleaseRepo = 0 ]]; then
        noCurrentReleaseRepo=1
        println_blue "noCurrentReleaseRepo ON.\\n The repos will be installed against ${previousStableReleaseName}."
        log_debug "noCurrentReleaseRepo ON.\\n The repos will be installed against ${previousStableReleaseName}."
      else
        noCurrentReleaseRepo=0
        println_blue "noCurrentReleaseRepo OFF.\\n The repos will be installed against ${distReleaseName}."
        log_debug "noCurrentReleaseRepo OFF.\\n The repos will be installed against ${distReleaseName}."
      fi
    ;;
  esac
}

selectDesktopEnvironment(){
  clear
  until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
    printf "\\n\\n"
    printf "  Desktop Environment is: %s%s%s%s\\n\\n" "${bold}" "${yellow}" "${desktopEnvironment}" "${normal}"
    printf "
    There are the following desktop environment options
    TASK : DESCRIPTION
    -----: ---------------------------------------\\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "gnome" ]]; then printf "%s%s1%s" "${rev}" "${bold}" "${normal}"; else printf "1"; fi; printf "   : Set desktop environment as gnome.\\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "kde" ]]; then printf "%s%s2%s" "${rev}" "${bold}" "${normal}"; else printf "2"; fi; printf "   : Set desktop environment as KDE.\\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "ubuntu" ]]; then printf "%s%s3%s" "${rev}" "${bold}" "${normal}"; else printf "3"; fi; printf "   : Set desktop environment as Ubuntu Unity.\\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "xubuntu" ]]; then printf "%s%s4%s" "${rev}" "${bold}" "${normal}"; else printf "4"; fi; printf "   : Set desktop environment as XFCE (Xubuntu).\\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "lubuntu" ]]; then printf "%s%s5%s" "${rev}" "${bold}" "${normal}"; else printf "5"; fi; printf "   : Set desktop environment as LXDE (Lubuntu).\\n"
    printf "\\n"
    printf "     0/q  : Return to Selection menu\\n\\n"

    read -rp "Enter your choice : " choiceOpt
    printf "\\n"
    if ((1<=choiceOpt && choiceOpt<=5))
    then
      case $choiceOpt in
        1 )
          desktopEnvironment="gnome"
        ;;
        2 )
          desktopEnvironment="kde"
        ;;
        3 )
          desktopEnvironment="ubuntu"
        ;;
        4 )
          desktopEnvironment="xubuntu"
        ;;
        5 )
          desktopEnvironment="lubuntu"
        ;;
      esac
      clear
    else
      clear
      println_red "\\nPlease enter a valid choice from 1-5.\\n"
    fi
  done
  choiceOpt=NULL
}

# ############################################################################
# Main Menu
mainMenu() {
  local choiceMain=NULL

  until [[ "$choiceMain" =~ ^(0|q|Q|quit)$ ]]; do
    clear
    println_info "\\n"
    println_info "BuildMan                                                    "
    println_info "====================================================================="

    # printf \\n    MESSAGE : In case of options, one value is displayed as the default value.\\n"
    # printf "    Do erase it to use other value.\\n"

    printf "\\n    BuildMan %s\\n" $buildmanVersion
    printf "\\n    This script is documented in README.md file.\\n"
    printf "\\n    Running: "
    println_yellow "${distReleaseName} ${distReleaseVer} ${desktopEnvironment}\\n"
    printf "\\n    There are the following options for this script\\n"
    printf "\\n    TASK :     DESCRIPTION\\n\\n"
    printf "    1    : Questions asked is "; if [[ "$noPrompt" = 1 ]]; then printf "%s%sOFF%s" "$bold" "$green" "$normal"; else printf "%s%s%sON%s" "$rev" "$bold" "$red" "$normal"; fi; printf ".\\n"
    printf "            Select 1 to toggle so that questions are "; if [[ "$noPrompt" = 1 ]]; then printf "%sASKED%s" "${bold}" "${normal}"; else printf "%sNOT ASKED%s" "${bold}" "${normal}"; fi; printf ".\\n";
    printf "    2    : Change to older Release Repositories is "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%s%s%sON%s" "${rev}" "${bold}" "${red}" "${normal}"; else printf "%s%sOFF%s" "$bold" "${green}" "$normal"; fi; printf ".\\n"
    printf "            Select 2 to toggle older Release Repositories to "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%sOFF%s" "${bold}" "${normal}"; else printf "%sON%s" "${bold}" "${normal}"; fi; printf ".\\n";
    printf "    3    : Install on a Beta version is "; if [[ "$betaAns" = 1 ]]; then printf "%s%s%sON%s" "${rev}" "${bold}" "${red}" "${normal}"; else printf "%s%sOFF%s" "$bold" "${green}" "$normal"; fi; printf ".\\n"
    printf "            Select 3 to toggle the install for a beta version to "; if [[ "$betaAns" = 1 ]]; then printf "%sOFF%s" "${bold}" "${normal}"; else printf "%sON%s" "${bold}" "${normal}"; fi; printf ".\\n";
    printf "    4    : Identified Desktop is %s%s%s%s. Select 4 to change.\\n" "${yellow}" "${bold}" "$desktopEnvironment" "${normal}"
    printf "    5    : Add user %s%s%s to sudoers.\\n\\n" "$bold" "$USER" "$normal"
    printf "    6    : Select the applications and then run uninterupted.
    7    : Select the applications and then run each item individually
    8    : Install applications from the menu one by one.

    10   : Install Laptop with pre-selected applications
    11   : Install Workstation with pre-selected applications
    12   : Install a Virtual Machine with pre-selected applications

    15   : Run a VirtualBox full test run, all apps.

    0/q  : Quit this program

    "
    printf "Enter your system password if asked...\\n\\n"

    read -rp "Enter your choice : " choiceMain
    printf "\\n"

    # if [[ $choiceMain == 'q' ]]; then
    # 	exit 0
    # fi


    # take inputs and perform as necessary
    case "$choiceMain" in
      1)
        if [[ $noPrompt = 0 ]]; then
          noPrompt=1
          println_blue "Questions asked is OFF.\\n No questions will be asked."
          log_debug "Questions asked is OFF.\\n No questions will be asked."
        else
          noPrompt=0
          println_blue "Questions asked is ON.\\n All questions will be asked."
          log_debug "Questions asked is ON.\\n All questions will be asked."
        fi
      ;;
      2)
        if [[ $noCurrentReleaseRepo = 0 ]]; then
          noCurrentReleaseRepo=1
          println_blue "Using older repositories ON.\\n The repos will be installed against ${previousStableReleaseName}."
          log_debug "Using older repositories ON.\\n The repos will be installed against ${previousStableReleaseName}."
        else
          noCurrentReleaseRepo=0
          println_blue "Using older repositories OFF.\\n The repos will be installed against ${distReleaseName}."
          log_debug "Using older repositories OFF.\\n The repos will be installed against ${distReleaseName}."
        fi
      ;;
      3)
        if [[ $betaAns = 0 ]]; then
          betaAns=1
          println_blue "Beta release is ON.\\n The repos will be installed against ${stableReleaseName}."
          log_debug "Beta release is ON.\\n The repos will be installed against ${stableReleaseName}."
        else
          betaAns=0
          println_blue "Beta release is OFF.\\n The repos will be installed against ${distReleaseName}."
          log_debug "Beta release is OFF.\\n The repos will be installed against ${distReleaseName}."
        fi
      ;;
      4 )
        selectDesktopEnvironment
      ;;
      5 )
      echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
      ;;
      6 )
        menuRun "SelectThenAutoRun"
      ;;
      7 )
        menuRun "SelectThenStepRun"
      ;;
      8 )
        menuRun "SelectItem"
      ;;
      10 )
        # Install Laptop with pre-selected applications
        menuSelectionsInput=(111 112 113 125 121 122 161 811 162 163 321 323 341 331 311 212 441 291 271 272 252 251 241 231 421 511 512 541 541 611 622 631 641 711 713 712 721 651 612 822 881 851)
        case $desktopEnvironment in
          gnome )
            menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
          kde )
            menuSelectionsInput+=(141 143 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(114 112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated installation for a Laptop\\n"
          menuRun "SelectThenAutoRun" "${menuSelectionsInput[@]}"
          pressEnterToContinue "Automated installation for a Laptop completed successfully."
        else
          println_info "Step install for a Laptop\\n"
          menuRun "SelectThenStepRun" "${menuSelectionsInput[@]}"
          pressEnterToContinue "Automated installation for a Laptop completed successfully."
        fi
      ;;
      11 )
        # Install Workstation with pre-selected applications
        menuSelectionsInput=(111 112 113 125 121 122 161 811 162 163 321 323 341 331 311 212 441 291 271 272 252 251 241 231 421 511 512 541 541 611 622 631 641 711 713 712 721 651 612 822 881 851)
        case $desktopEnvironment in
          gnome )
            menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
          kde )
            menuSelectionsInput+=(141 143 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(114 112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated installation for a Workstation\\n"
          menuRun "SelectThenAutoRun" "${menuSelectionsInput[@]}"
          pressEnterToContinue "Automated installation for a Workstation completed successfully."
        else
          println_info "Step select installation for a Workstation.\\n"
          menuRun "SelectThenStepRun" "${menuSelectionsInput[@]}"
          pressEnterToContinue "Step select installation for a Workstation completed successfully."
        fi
      ;;
      12 )
        # Install a Virtual Machine with pre-selected applications
        menuSelectionsInput=(111 112 113 121 122 212 271 241)
        case $desktopEnvironment in
          gnome )
            menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
          kde )
            menuSelectionsInput+=(141 143 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(114 112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated install for a virtual machine\\n"
          menuRun "AutoRun" "${menuSelectionsInput[@]}"
          println_info "Virtual machine automated install completed."
        else
          println_info "Step install for a virtual machine\\n"
          menuRun "SelectThenStepRun" "${menuSelectionsInput[@]}"
          println_info "Virtual machine step install completed."
        fi
      ;;
      15 )
        # Run a VirtualBox full test run, all apps.
        menuSelectionsInput=(131 111 112 113 125 121 122 141 142 151 152 161 811 162 163 321 324 323 311 212 213 221 222 461 421 441 442 291 271 312 272 281 252 251 241 511 512 541 541 513 595 586 585 611 621 631 641 721 612 881 851 451)
        case $desktopEnvironment in
          gnome )
            menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
          kde )
            menuSelectionsInput+=(141 142 143 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(114 112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated Test install all apps on a VirtualBox VM\\n"
          menuRun "SelectThenAutoRun" "${menuSelectionsInput[@]}"
          println_info "All apps on VirtualBox automated install completed."
        else
          println_info "Step Test install all apps on a VirtualBox VM\\n"
          menuRun "SelectThenStepRun" "${menuSelectionsInput[@]}"
          println_info "All apps on VirtualBox stepped install completed."
        fi
      ;;
      0|q)
        return 0
      ;;
      # *);;
    esac
  done
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O           Main Script                                                    O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Here is where the main script starts
# Above were the functions to be used
# ########################################################
# Set global variables
desktopEnvironmentCheck

if [[ "$betaReleaseName" == "$distReleaseName" ]] || [[ "$betaReleaseVer" == "$distReleaseVer" ]]; then
  betaAns=1
else
  stableReleaseVer=$distReleaseVer
  stableReleaseName=$distReleaseName
fi

# Logs start
{
  log_warning "desktopEnvironment=$desktopEnvironment"
  log_warning "distReleaseVer=$distReleaseVer"
  log_warning "distReleaseName=$distReleaseName"
  log_warning "stableReleaseVer=$stableReleaseVer"
  log_warning "stableReleaseName=$stableReleaseName"
  log_warning "ltsReleaseName=$ltsReleaseName"
  log_warning "betaReleaseName=$betaReleaseName"
  log_warning "betaAns=$betaAns"
  log_info "\\nStart of BuildMan"
  log_info "===================================================================="
  # println_yellow "desktopEnvironment=$desktopEnvironment"
  # println_yellow "distReleaseVer=$distReleaseVer"
  # println_yellow "distReleaseName=$distReleaseName"
  # println_yellow "stableReleaseVer=$stableReleaseVer"
  # println_yellow "stableReleaseName=$stableReleaseName"
  # println_yellow "ltsReleaseName=$ltsReleaseName"
  # println_yellow "betaReleaseName=$betaReleaseName"
  # println_yellow "betaAns=$betaAns"
}

mainMenu

# Logs end
{
  log_info "Jobs done!"
  log_info "End of BuildMan"
  log_info "===================================================================="
}

printf "\\n\\nJob done!\\n"
printf "Thanks for using. :-)\\n"
# ############################################################################
# set debugging off
# set -xv
exit;
