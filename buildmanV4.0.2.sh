#!/bin/bash

# DateVer 2019/01/22
# Buildman
buildmanVersion=V4.0.2
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

# Ready for Bionic
# Global Variables
{
  betaReleaseName="disco"
  betaReleaseVer="19.04"
  stableReleaseName="cosmic"
  stableReleaseVer="18.10"
  previousStableReleaseName="bionic"
  previousStableReleaseVer="18.04"
  noCurrentReleaseRepo=0
  betaAns=0

  ltsReleaseName="bionic"
  desktopEnvironment=""
  kernelRelease=$(uname -r)
  distReleaseVer=$(lsb_release -sr)
  distReleaseName=$(lsb_release -sc)
  noPrompt=0
  debugLogFile="/tmp/buildman.log"
  errorLogFile="/tmp/buildman_error.log"

  HOMEDIR=$HOME
  mkdir -p "$HOMEDIR/tmp"
  sudo chown "$USER":"$USER" "$HOMEDIR/tmp"

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
    echo -en "\n \033[1;31m   ##############################################################\n\033[0m
    \n
    \033[1;31m START OF NEW RUN\n\033[0m
    \n
    \033[1;31m###############################################################\n\033[0m\n" >>"$debugLogFile"
  else
    touch "$debugLogFile"
  fi
  if [[ -e $errorLogFile ]]; then
    echo -en "\n \033[1;31m##############################################################\n\033[0m
    \n
    \033[1;31m START OF NEW RUN\n\033[0m
    \n
    \033[1;31m###############################################################\n\033[0m\n" >>"$errorLogFile"
    echo -en "\n" >>"$errorLogFile"
  else
    touch "$errorLogFile"
  fi
fi

# ############################################################################
# debug function - replaced by log4bash
debug () {
  #[[ $script_debug = 1 ]] && "$@" || :

  #printf "DEBUG: %s\n" "$1"
  if [[ $scriptDebugToStdout == "on" ]]
  then
    printf "DEBUG: %q\n" "$@"
  fi
  if [[ $scriptDebugToFile == "on" ]]
  then
    printf "DEBUG: %q\n" "$@" >>"$debugLogFile" 2>>"$errorLogFile"
  fi
  # [[ $script_debug = 1 ]] && printf "DEBUG: %q\n" "$@" >>$debugLogFile 2>>$errorLogFile || :
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
  mkdir -p "$HOMEDIR/hostfiles/home"
  mkdir -p "$HOMEDIR/hostfiles/data"
  LINE1="172.22.8.1:/home/juanb/      $HOMEDIR/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="172.22.8.1:/data      $HOMEDIR/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  LINE3="172.22.1.1:/home/juanb/      $HOMEDIR/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE3|h; \${x;s|$LINE3||;{g;t};a\\" -e "$LINE3" -e "}" /etc/fstab
  LINE4="172.22.1.1:/data      $HOMEDIR/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE4|h; \${x;s|$LINE4||;{g;t};a\\" -e "$LINE4" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" "$HOMEDIR/hostfiles"
  # sudo mount -a
}

# ############################################################################
# VirtualBox Host Setup
virtualboxHostInstall () {
  log_info "VirtualBox Host setup"
  println_blue "VirtualBox Host setup                                                         "

  # Uncomment to add repository and get latest releases
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
  echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $distReleaseName contrib" | sudo tee "/etc/apt/sources.list.d/virtualbox-$distReleaseName.list"
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Virtualbox apt sources."
    println_red "Beta Code, revert the Virtaulbox apt sources."
    changeAptSource "/etc/apt/sources.list.d/virtualbox-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    # repoUpdate
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Virtualbox apt sources."
    println_red "No new repo, revert the Virtaulbox apt sources."
    changeAptSource "/etc/apt/sources.list.d/virtualbox-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  fi
  repoUpdate
  # Uncomment up the here

  # VirtualBox 5.1
  # sudo apt install virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso virtualbox-qt vde2 vde2-cryptcab qemu qemu-user-static qemu-efi openbios-ppc openhackware dkms
  #VirtualBox from Universe
  # sudo apt install -y virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso vde2 vde2-cryptcab qemu qemu-user-static qemu-efi openbios-ppc openhackware dkms
  #VirtualBox 5.2 from VirtaulBox Repo
  # sudo apt install -y virtualbox-5.2 vde2 vde2-cryptcab qemu qemu-user-static qemu-efi openbios-ppc openhackware dkms
  #VirtualBox 6.0 from VirtaulBox Repo
  sudo apt install -y virtualbox-6.0 vde2 vde2-cryptcab qemu qemu-user-static qemu-efi openbios-ppc openhackware dkms
  # sudo apt install -y virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso
  # case $desktopEnvironment in
  #   "kde" )
  #   # sudo apt install -y virtualbox-qt;
  #   ;;
  # esac


  # LINE1="192.168.56.1:/home/juanb/      $HOMEDIR/hostfiles/home    nfs     rw,intr    0       0"
  # sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  # LINE2="192.168.56.1:/data      $HOMEDIR/hostfiles/data    nfs     rw,intr    0       0"
  # sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  # sudo mount -a
}

# ############################################################################
# VirtualBox Guest Setup, vmtools, nfs directories to host
virtualboxGuestSetup () {
  log_info "VirtualBox setup NFS file share to hostfiles"
  println_blue "VirtualBox setup NFS file share to hostfiles                         "
  sudo apt install -y nfs-common ssh virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
  mkdir -p "$HOMEDIR/hostfiles/home"
  mkdir -p "$HOMEDIR/hostfiles/data"
  LINE1="192.168.56.1:/home/juanb/      $HOMEDIR/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="192.168.56.1:/data      $HOMEDIR/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" "$HOMEDIR/hostfiles"
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
  cd "$HOMEDIR" || exit

  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    sudo chown -R "$USER:$USER" /data
    if [ -d "$HOMEDIR/$sourceDataDirectory" ]; then
      if [ -L "$HOMEDIR/$sourceDataDirectory" ]; then
        # It is a symlink!
        log_info "Keep symlink $HOMEDIR/data"
        # log_debug "Remove symlink $HOMEDIR/data"
        # rm "$HOMEDIR/$sourceDataDirectory"
        # ln -s "/data" "$HOMEDIR/$sourceDataDirectory"
      else
        # It's a directory!
        # log_debug "Remove directory $HOMEDIR/data"
        rm -R "${HOME}/${sourceDataDirectory}:?"
        ln -s "/data" "$HOMEDIR/$sourceDataDirectory"
      fi
    else
      # log_debug "Link directory $HOMEDIR/data"
      ln -s "/data" "$HOMEDIR/$sourceDataDirectory"
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
  cd "$HOMEDIR" || exit


  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    if [ -d "$HOMEDIR/$sourceDataDirectory" ]; then
      if [ -L "$HOMEDIR/$sourceDataDirectory" ]; then
        # It is a symlink!
        log_debug "Keep symlink $HOMEDIR/data"
        # log_warning "Remove symlink $HOMEDIR/data"
        # rm "$HOMEDIR/$sourceDataDirectory"
        # ln -s "/data" "$HOMEDIR/$sourceDataDirectory"
      else
        # It's a directory!
        log_debug "Remove directory $HOMEDIR/data"
        rm -R "${DATADIR}/${sourceDataDirectory}:?"
        ln -s "/data" "$HOMEDIR/$sourceDataDirectory"
      fi
    else
      log_debug "Link directory $HOMEDIR/data"
      ln -s "/data" "$HOMEDIR/$sourceDataDirectory"
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
      if [ -e "$HOMEDIR/$sourceLinkDirectory" ]; then
        if [ -d "$HOMEDIR/$sourceLinkDirectory" ]; then
          if [ -L "$HOMEDIR/$sourceLinkDirectory" ]; then
            # It is a symlink!
            # log_debug "Remove symlink $HOMEDIR/$sourceLinkDirectory"
            # rm "$HOMEDIR/$sourceLinkDirectory"
            ln -sf "/data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          else
            # It's a directory!
            # log_debug "Remove directory $HOMEDIR/data"
            rmdir -r "$HOMEDIR/$sourceLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          fi
        else
          rm "$HOMEDIR/$sourceLinkDirectory"
          ln -sf "/data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
        fi
      else
        # log_debug "$HOMEDIR/$sourceLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOMEDIR/$sourceLinkDirectory" ];  then
          # It is a symlink!
          # log_debug "Remove symlink $HOMEDIR/$sourceLinkDirectory"
          # rm "$HOMEDIR/$sourceLinkDirectory"
          ln -sf "/data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOMEDIR/$sourceLinkDirectory"
        else
          ln -s "/data/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
        fi
        # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOMEDIR/$sourceLinkDirectory"
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
      if [ -e "$HOMEDIR/$targetLinkDirectory" ]; then
        if [ -d "$HOMEDIR/$targetLinkDirectory" ]; then
          if [ -L "$HOMEDIR/$targetLinkDirectory" ]; then
            # It is a symlink!
            # log_debug "Remove symlink $HOMEDIR/$targetLinkDirectory"
            rm "$HOMEDIR/$targetLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          else
            # It's a directory!
            # log_debug "Remove directory $HOMEDIR/data"
            rmdir "$HOMEDIR/$targetLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
            # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          fi
        else
          rm "$HOMEDIR/$targetLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
        fi
      else
        # log_debug "$HOMEDIR/$targetLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOMEDIR/$targetLinkDirectory" ];  then
          # It is a symlink!
          # log_debug "Remove symlink $HOMEDIR/$targetLinkDirectory"
          rm "$HOMEDIR/$targetLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOMEDIR/$targetLinkDirectory"
        fi
        ln -s "/data/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
        # log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOMEDIR/$targetLinkDirectory"
      fi
    done

  #   # For Firefox only
  #   if [[ "$noPrompt" -eq 0 ]]; then
  #     read -rp "Do you want to link to Data's Firefox (y/n): " qfirefox
  #     if [[ $qfirefox = [Yy1] ]]; then
  #       sourceLinkDirectory="$HOMEDIR/.mozilla"
  #       if [ -d "$sourceLinkDirectory" ]; then
  #         rm -R "$sourceLinkDirectory"
  #         ln -s /data/.mozilla "$sourceLinkDirectory"
  #       fi
  #     fi
  #   else
  #     sourceLinkDirectory"$HOMEDIR/.mozilla"
  #     if [ -d "$sourceLinkDirectory" ]; then
  #       rm -R "$sourceLinkDirectory"
  #       ln -s /data/.mozilla "$sourceLinkDirectory"
  #     fi
  #   fi
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

  if [[ $betaAns != 1 ]] && [[ $noCurrentReleaseRepo != 1 ]]; then
    wget -q -O - "https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$distReleaseVer/Release.key" | sudo apt-key add -
    echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$distReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$distReleaseName.list"
  elif [[ $betaAns == 1 ]]; then
    wget -q -O - "https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$stableReleaseVer/Release.key" | sudo apt-key add -
    echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$stableReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$stableReleaseName.list"
  else
    wget -q -O - "https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$previousStableReleaseVer/Release.key" | sudo apt-key add -
    echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$previousStableReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$previousStableReleaseName.list"
  fi
  repoUpdate
  sudo apt install -yf owncloud-client
  # sudo apt install -yf
}

# ############################################################################
# DisplayLink Software install
displayLinkInstallApp () {

  currentPath=$(pwd)
  log_info "display Link Install App"
  println_blue "display Link Install App                                             "
	sudo apt install -y libegl1-mesa-drivers xserver-xorg-video-all xserver-xorg-input-all dkms libwayland-egl1-mesa

  cd "$HOMEDIR/tmp" || return
	wget -r -t 10 --output-document=displaylink.zip  http://www.displaylink.com/downloads/file?id=1123
  mkdir -p "$HOMEDIR/tmp/displaylink"
  unzip displaylink.zip -d "$HOMEDIR/tmp/displaylink/"
  chmod +x "$HOMEDIR/tmp/displaylink/displaylink-driver-4.2.run"
  sudo "$HOMEDIR/tmp/displaylink/displaylink-driver-4.2.run"

  sudo chown -R "$USER":"$USER" "$HOMEDIR/tmp/displaylink/"
  cd "$currentPath" || return
  sudo apt install -yf
}

# ############################################################################
# XPS Display Drivers inatallations
laptopDisplayDrivers () {
  log_info "Install XPS Display Drivers"
  println_blue "Install XPS Display Drivers                                          "
  #get intel key for PPA that gets added during install
  wget --no-check-certificate https://download.01.org/gfx/RPM-GPG-GROUP-KEY-ilg -O - | sudo apt-key add -
  sudo apt install -y nvidia-current intel-graphics-update-tool
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                   Window Managers Backports                              O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# gnome3Backports
gnome3Backports () {
  log_info "Install Gnome3 Backports"
  println_blue "Install Gnome3 Backports                                                      "
  sudo add-apt-repository -y ppa:gnome3-team/gnome3-staging
  sudo add-apt-repository -y ppa:gnome3-team/gnome3
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Gnome3 apt sources."
    println_red "Beta Code, revert the Gnome3 apt sources."
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-staging-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Gnome3 apt sources."
    println_red "No new repo, revert the Gnome3 apt sources."
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-staging-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  fi

  repoUpdate
	repoUpgrade
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
  # if [[ $betaAns == 1 ]] || [[ $noCurrentReleaseRepo == 1 ]]; then
  #   log_warning "Beta Code or no new repo, revert the KDE Backports apt sources."
  #   println_red "Beta Code or no new repo, revert the KDE Backports apt sources."
  #   changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  #   changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-landing-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  #   repoUpdate
  # fi

  repoUpdate
  repoUpgrade
  sudo apt full-upgrade -y;
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
  sudo apt install -y curl
  curl -sL https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
  sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
  repoUpdate
  # sudo snap install shellcheck
  sudo snap install eclipse --classic
  # sudo snap install atom --classic
  sudo apt install -yf atom abs-guide idle3 idle3-tools eric eric-api-files maven shellcheck hunspell hunspell-af hunspell-en-us hunspell-en-za hunspell-en-gb geany;
  # wget -P "$HOMEDIR/tmp" https://release.gitkraken.com/linux/gitkraken-amd64.deb
  # sudo dpkg -i --force-depends "$HOMEDIR/tmp/gitkraken-amd64.deb"
  # bashdbInstall
  # The following packages was installed in the past but never used or I could not figure out how to use them.
  #
  # sudo snap install --classic --beta atom
  if [[ "$noPrompt" -eq 0 ]]; then
    read -rp "Do you want to install from the repo(default) or Snap? (repo/snap)" answer
    if [[ $answer = "snap" ]]; then
      sudo snap install atom
      sudo apt install -yf shellcheck hunspell hunspell-af hunspell-en-
    else
      sudo apt install -y curl
      curl -sL https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
      sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
      repoUpdate
      # sudo snap install atom --classic
      sudo apt install -yf atom shellcheck hunspell hunspell-af hunspell-en-
    fi
  else
    sudo apt install -y curl
    curl -sL https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
    repoUpdate
    # sudo snap install atom --classic
    sudo apt install -yf atom shellcheck hunspell hunspell-af hunspell-en-
  fi

  cd "$currentPath" || return
}

# ############################################################################
# Git packages installation
gitInstall() {
  currentPath=$(pwd)
  log_info "Git Apps install"
  println_banner_yellow "Git Apps install                                                     "
  sudo apt install -y gitk git-flow giggle gitg git-cola
  sudo snap install gitkraken
  sudo apt install -yf
  cd "$currentPath" || return
}

# ############################################################################
# Bashdb packages installation
bashdbInstall() {
  currentPath=$(pwd)
  log_info "Bash Debugger 4.4-0.94 install"
  println_banner_yellow "Bash Debugger 4.4-0.94 install                                       "
  cd "$HOMEDIR/tmp" || die "Path $HOMEDIR/tmp does not exist."
  # wget https://netix.dl.sourceforge.net/project/bashdb/bashdb/4.4-0.94/bashdb-4.4-0.94.tar.gz
  curl -# -o bashdb.tar.gz https://netix.dl.sourceforge.net/project/bashdb/bashdb/4.4-0.94/bashdb-4.4-0.94.tar.gz
  tar -xzf "$HOMEDIR/tmp/bashdb.tar.gz"
  cd "$HOMEDIR/tmp/bashdb-4.4-0.94" || die "Path bashdb-4.4-0.94 does not exist"
  ./configure
  make
  sudo make install

  cd "$currentPath" || die "Could not cd $currentPath."
}

# ############################################################################
# Visual Studio Code Install
vscodeInstall() {
  sudo snap install --classic vscode
}

# ############################################################################
# PyCharm Install
pycharmInstall() {
  sudo snap install pycharm-community --classic
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
# Brackets DevApp installation
bracketsInstall() {
  # Brackets
  println_blue "Brackets"
  log_info "Brackets"
  sudo snap install brackets --classic
}

# ############################################################################
# Postman DevApp installation
postmanInstall() {
  # Postman
  println_blue "Postman"
  log_info "Postman"
  sudo snap install postman
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
  sudo apt install -y fonts-inconsolata ttf-staypuft ttf-dejavu-extra fonts-dustin ttf-marvosym fonts-breip fonts-dkg-handwriting ttf-isabella ttf-summersby ttf-sjfonts ttf-mscorefonts-installer ttf-xfree86-nonfree cabextract t1-xfree86-nonfree ttf-dejavu ttf-georgewilliams ttf-bitstream-vera ttf-dejavu ttf-dejavu-extra ttf-aenigma fonts-firacode;
	# sudo apt install -y  ttf-dejavu-udeb ttf-dejavu-mono-udeb ttf-liberation ttf-freefont;
}

# ############################################################################
# Install Opera browser
operaInstall () {
  log_info "Install Opera browser"
  println_blue "Install Opera browser"
  sudo snap install opera
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
  sudo snap install mailspring
}

# ############################################################################
# Install Winds
windsInstall () {
  log_info "Install Winds RSS Reader and Podcast application"
  println_blue "Install Winds RSS Reader and Podcast application"
  sudo snap install winds
}

# ############################################################################
# Install Skype
skypeInstall () {
  log_info "Install Skype"
  println_blue "Install Skype"
  sudo snap install skype --classic
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
  # wget -nv https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_18.04/Release.key -O "$HOMEDIR/tmp/Release.key" | sudo apt-key add -
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
  # sudo apt-add-repository -y ppa:alexx2000/doublecmd

  repoUpdate
  sudo apt install -y doublecmd-qt5 doublecmd-help-en doublecmd-plugins
}

# ############################################################################
# KVM Install
kvmInstall () {
  log_info "KVM Applications Install"
  println_blue "KVM Applications Install                                               "

  if ! [[ "$distReleaseName" =~ ^(cosmic)$ ]]; then
    sudo apt install -y qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker virt-manager
  else
    sudo apt install -y qemu-kvm libvirt-clients libvirt-daemon virtinst bridge-utils cpu-checker virt-manager linux-image-kvm linux-kvm linux-image-virtual linux-tools-kvm aqemu

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

	# Change the images and containers directory to /data/docker
	# Un comment the following if it is a new install and comment the rm line
	# sudo mv /var/lib/docker /data/docker
  if [ -d "/data" ]; then
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
	printf "Logout and login for the user to be added to the group\n"
	printf "\nGo to https://docs.docker.com/engine/installation/ubuntulinux/ for DNS and Firewall setup\n\n"
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
  sudo apt-add-repository -y ppa:brightbox/ruby-ng
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Ruby Repo apt sources."
    println_red "Beta Code, revert the Ruby Repo apt sources."
    changeAptSource "/etc/apt/sources.list.d/brightbox-ubuntu-ruby-ng-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Ruby Repo apt sources."
    println_red "No new repo, revert the Ruby Repo apt sources."
    changeAptSource "/etc/apt/sources.list.d/brightbox-ubuntu-ruby-ng-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi
}

# ############################################################################
# Vagrant Install, vmtools, nfs directories to host
vagrantInstall () {
  log_info "Vagrant Applications Install"
  println_blue "Vagrant Applications Install                                               "
  rubyRepo
  sudo add-apt-repository -y ppa:tiagohillebrandt/vagrant
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Vagrant apt sources."
    println_red "Beta Code, revert the Vagrant apt sources."
    changeAptSource "/etc/apt/sources.list.d/tiagohillebrandt-ubuntu-vagrant-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Vagrant apt sources."
    println_red "No new repo, revert the Vagrant apt sources."
    changeAptSource "/etc/apt/sources.list.d/tiagohillebrandt-ubuntu-vagrant-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
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

  rubyRepo
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
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
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
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Beta Code or no new repo, revert the Y-PPA Manager apt sources."
    println_red "Beta Code or no new repo, revert the Y-PPA Manager apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi
  sudo apt install -y y-ppa-manager
}

# ############################################################################
# Oracle Java  Installer from WebUpd8 packages installation
oracleJava8Install() {
  log_info "Oracle Java8 Installer from WebUpd8"
  println_blue "Oracle Java8 Installer from WebUpd8"
  sudo add-apt-repository -y ppa:webupd8team/java
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Oracle Java 8 apt sources."
    println_red "Beta Code, revert the Oracle Java 8 apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Oracle Java 8 apt sources."
    println_red "No new repo, revert the Oracle Java 8 apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate

  fi
  sudo apt install -y oracle-java8-installer
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
  sudo apt install -y oracle-java11-installer
  sudo apt install -y oracle-java11-set-default
}

# ############################################################################
# Grub Customizer packages installation
grubCustomizerInstall() {
  log_info "Grub Customizer Appliction Install"
  println_blue "Grub Customizer Application Install"
  sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Distribution, downgrade Grub Customizer apt sources."
    println_red "Beta Distribution, downgrade Grub Customizer apt sources."
    changeAptSource "/etc/apt/sources.list.d/danielrichter2007-ubuntu-grub-customizer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
  sudo apt install -y grub-customizer
}

# ############################################################################
# Variety packages installation
varietyInstall() {
  log_info "Variety Appliction Install"
  println_blue "Variety Application Install"
  sudo add-apt-repository -y ppa:peterlevi/ppa
  # sudo add-apt-repository -y ppa:variety/daily

  sudo apt install -y variety variety-slideshow python3-pip
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
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
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
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the UNetbootin apt sources."
    println_red "Beta Code, revert the UNetbootin apt sources."
    changeAptSource "/etc/apt/sources.list.d/gezakovacs-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the UNetbootin apt sources."
    println_red "No new repo, revert the UNetbootin apt sources."
    changeAptSource "/etc/apt/sources.list.d/gezakovacs-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
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
    if [[ $answer = "appimage" ]]; then
      curl -s https://github.com/resin-io/etcher/releases/latest | grep "etcher-electron-*-x86_64.AppImage" | cut -d '"' -f 4   | wget -qi -
    else
      echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
      repoUpdate
      sudo apt install balena-etcher-electron
    fi
  else
    echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
    repoUpdate
    sudo apt install balena-etcher-electron
  fi
}

# ############################################################################
# rEFInd Boot Manager packages installation
rEFIndInstall() {
  log_info "rEFInd Boot Manager Appliction Install"
  println_blue "rEFInd Boot Manager Application Install"
  sudo apt-add-repository -y ppa:rodsmith/refind
  sudo apt install -y refind
}

# ############################################################################
# Stacer Linux system info and cleaner packages installation
stacerInstall() {
  log_info "Stacer Linux System Optimizer and Monitoring Appliction Install"
  println_blue "Stacer Linux System Optimizer and Monitoring Application Install"
  sudo add-apt-repository -y ppa:oguzhaninan/stacer
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Stacer apt sources."
    println_red "Beta Code, revert the Stacer apt sources."
    changeAptSource "/etc/apt/sources.list.d/oguzhaninan-ubuntu-stacer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Stacer apt sources."
    println_red "No new repo, revert the Stacer apt sources."
    changeAptSource "/etc/apt/sources.list.d/oguzhaninan-ubuntu-stacer-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
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
  sudo snap install bitwarden
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
  log_info "Filezilla, PyCharm, Calibre, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync"
  println_blue "Filezilla, PyCharm, Calibre, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync"
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
  sudo add-apt-repository -y ppa:rikmills/latte-dock
  sudo apt install -y latte-dock
  kwriteconfig5 --file "$HOMEDIR/.config/kwinrc" --group ModifierOnlyShortcuts --key Meta "org.kde.lattedock,/Latte,org.kde.LatteDock,activateLauncherMenu"
  qdbus org.kde.KWin /KWin reconfigure
}

# ############################################################################
# LibreCAD installation
librecadInstall() {
  log_info "Install LibreCAD"
  println_blue "Install LibreCAD"

  # sudo add-apt-repository -y ppa:librecad-dev/librecad-stable
  sudo add-apt-repository -y ppa:librecad-dev/librecad-daily
  changeAptSource "/etc/apt/sources.list.d/librecad-dev-ubuntu-librecad-stable-$distReleaseName.list" "$distReleaseName" $ltsReleaseName

  repoUpdate

  sudo apt install -y librecad
}

# ############################################################################
# Calibre installation
calibreInstall() {
  log_info "Calibre"
  println_blue "Calibre"

  sudo apt install -y calibre

  # sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
  # Use the following f you get certificate issues
  # sudo -v && wget --no-check-certificate -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

  # Github download, above is recommended
  # sudo -v && wget --no-check-certificate -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"
}

# ############################################################################
# Powerline installation
powerlineInstall() {
  log_info "Powerline"
  println_blue "Powerline"

  sudo apt install -y powerline powerline-doc powerline-gitstatus jsonlint
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
  sudo snap install inkscape
}

# ############################################################################
# Image Edfiting packages installation
imageEditingAppsInstall() {
  log_info "Imaging Editing Applications"
  println_blue "Imaging Editing Applications"
  sudo add-apt-repository -y ppa:otto-kesselgulasch/gimp
  # sudo apt install -y dia gimp gimp-plugin-registry gimp-ufraw;
  sudo apt install -y dia
  sudo snap install gimp
}

# ############################################################################
# Music and Videos packages installation
musicVideoAppsInstall() {
  log_info "Music and Video apps"
  println_blue "Music and Video apps"
  # sudo apt install -y vlc browser-plugin-vlc easytag
  sudo apt install -y easytag
  sudo snap install clementine
  sudo snap install vlc
}

# ############################################################################
# Install Spotify
spotifyInstall () {
  log_info "Install Spotify"
  println_blue "Install Spotify"
  sudo snap install spotify
}

# ############################################################################
# Install Google Play Music Desktop Player
google-play-music-desktop-playerInstall () {
  log_info "Install Google Play Music Desktop Player"
  println_blue "Install Google Play Music Desktop Player"
  sudo snap install google-play-music-desktop-player

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
  sudo snap install darktable
}

rapidPhotoDownloaderInstall() {
  # Rapid Photo downloader
  log_info "Rapid Photo downloader"
  println_blue "Rapid Photo downloader"
  wget -P "$HOMEDIR/tmp" https://launchpad.net/rapid/pyqt/0.9.4/+download/install.py
  cd "$HOMEDIR/tmp" || return
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
  sudo add-apt-repository -y ppa:alexlarsson/flatpak
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, revert the Flatpak apt sources."
    println_red "Beta Code, revert the Flatpak apt sources."
    changeAptSource "/etc/apt/sources.list.d/alexlarsson-ubuntu-flatpak-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    repoUpdate
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the Flatpak apt sources."
    println_red "No new repo, revert the Flatpak apt sources."
    changeAptSource "/etc/apt/sources.list.d/alexlarsson-ubuntu-flatpak-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi
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

	sudo apt install -yf gparted nfs-kernel-server nfs-common samba ssh sshfs rar gawk vim vim-gnome vim-doc tree meld bzr htop iptstate kerneltop vnstat nmon qpdfview terminator autofs openjdk-8-jdk openjdk-8-jre openjdk-11-jdk openjdk-11-jre dnsutils net-tools network-manager-openconnect network-manager-vpnc network-manager-ssh network-manager-vpnc network-manager-ssh network-manager-pptp openssl xdotool openconnect flatpak traceroute gcc make

	# desktop specific applications
	case $desktopEnvironment in
		"kde" )
			sudo apt install -y kubuntu-restricted-addons kubuntu-restricted-extras kfind
			;;
		"gnome" )
			sudo apt install -y gmountiso dconf-tools ubuntu-restricted-extras
			;;
		"ubuntu" )
			sudo apt install -y gmountiso dconf-tools ubuntu-restricted-extras
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
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "No new repo, revert the UGet Integrator apt sources."
    println_red "No new repo, revert the UGet Integrator apt sources."
    changeAptSource "/etc/apt/sources.list.d/uget-team-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    repoUpdate
  fi

	# general applications
  sudo apt install -yf
	sudo apt install -yf synaptic aptitude mc filezilla remmina rdiff-backup luckybackup printer-driver-cups-pdf keepassx flashplugin-installer ffmpeg keepnote workrave unison unison-gtk deluge-torrent liferea planner shutter chromium-browser blender caffeine gufw cockpit thunderbird uget uget-integrator glance

  # Older packages...
  # Still active, but replaced with other apps
  # unetbootin = etcher


  # older packages that will not install on new releases
  if ! [[ "$distReleaseName" =~ ^(yakkety|zesty|artful|bionic|cosmic|disco)$ ]]; then
   sudo apt install -yf scribes cnijfilter-common-64 cnijfilter-mx710series-64 scangearmp-common-64 scangearmp-mx710series-64
  fi
	# desktop specific applications
	case $desktopEnvironment in
		"kde" )
			sudo apt install -y kubuntu-restricted-addons kubuntu-restricted-extras amarok kdf k4dirstat filelight kde-config-cron kdesdk-dolphin-plugins kcron;
      latteDockInstall
      # Old packages:
      # ufw-kde
			;;
		"gnome" )
			sudo apt install -y gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky nautilus-image-converter wallch alacarte gnome-shell-extensions-gpaste ambiance-colors radiance-colors;
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
      printf "\n\n\n"
      println_yellow "Running $desktopEnvironment $distReleaseName $distReleaseVer"
      printf "
      There are the following options for selecting a stable release for the repositories
           that are known for not having beta or early releases:
      Key  : Stable Release
      -----: ---------------------------------------
      c    : 19.04 Disco Dingo
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
      printf "\n"
      case $stablechoice in
        d)
          stableReleaseName="cosmic"
          stableReleaseVer="18.10"
          betaReleaseName="disco"
          betaReleaseVer="19.04"
          previousStableReleaseName="bionic"
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
        quit|q|0)
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
  local menuSelections=($@)

  selectionMenu(){

    menuSelectionsInput=(
      111    #: Kernel upgrade
      112    #: Repositories update
      113    #: Repositories upgrade
      125    #: Install and configure Flatpak
      121    #: Install additional basic utilties and applications
      122    #: Install my selection of Universe applications
      131    #: Setup the home directories to link to the data disk directories

      141   #: Install KDE Desktop from backports
      142   #: Upgrae KDE to Beta KDE on backports
      143   #: Placeholder for KDE Desktop settings
      151   #: Install Gnome Desktop from backports
      152   #: Gnome Settings

      161   #: ownCloudClient
      811   #: Docker
      162   #: Dropbox
      163   #: inSync for GoogleDrive
      321   #: Thunderbird email
      324   #: Evolution email
      323   #: Mailspring desktop email client
      341   #: Winds RSS Reader and Podcast application
      331   #: Skype

      311   #: Google Chrome browser
      212   #: Doublecmd
      211   #: Latte Dock
      271   #: Y-PPA Manager
      291   #: Install extra fonts
      312   #: Opera browser

           #: submenuUtils
      272   #: bootRepair
      281   #: rEFInd Boot Manager
      261   #: UNetbootin
      251   #: Etcher USB Loader
      241   #: Stacer Linux system info and cleaner
      231   #: Bitwarden Password Manager
      213   #: FreeFileSync
      461   #: LibreCAD
      441   #: Calibre
      221  #: Powerline
      451  #: Anbox - Android Box

           #: submenuDev
      511   #: Install Development Apps and IDEs
      512   #: Git
      541   #: AsciiDoc
      521   #: Bashdb
      522   #: PyCharm
      523   #: Visual Studio Code
      524   #: Brackets IDE
      531  #: Postman
      591   #: Add Ruby Repositories
      552   #: Oracle Java 8
      553   #: Oracle Java 9
      551   #: Oracle Java Latest

           #: submenu Media and Photo
      611   #: Photography Apps
      621   #: Digikam
      622   #: Darktable
      631   #: RapidPhotoDownloader
      641   #: Image Editing Applications
      711   #: Music and Video Applications
      713   #: Spotify
      712   #: Google Play Music Desktop Player
      651   #: Inkscape
      612   #: Variety

           #: submenuVirtualization
      821   #: Setup for a VirtualBox guest
      822   #: VirtualBox Host
      831   #: Setup for a Vmware guest
      851   #: Vagrant
      881   #: KVM

           #: submenuOther
      911   #: Laptop Display Drivers for Intel en Nvidia
      921   #: DisplayLink

           #: submenuSettings
      191   #: Set options for an Ubuntu Beta install with PPA references to a previous version.
      132   #: Create test data directories on data drive.
      2   #: Toggle No Questions asked
      3   #: Toggle noCurrentReleaseRepo

      1   #: Run Selection
    )

    clear
    printf "\n\n"
    case $typeOfRun in
    SelectThenAutoRun )
      printf "  %s%sSelect items and then install the items without prompting.%s\n" "${rev}" "${bold}" "${normal}"
    ;;
    SelectThenStepRun )
      printf "  %s%sSelect items and then install the items each with a prompt.%s\n" "${rev}" "${bold}"  "${normal}"
    ;;
    SelectItem )
      printf "  %s%sSelect items and for individual installation with prompt.%s\n" "${rev}" "${bold}" "${normal}"
    esac
    printf "
    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "111" ]]; then printf "%s%s111%s" "${rev}" "${bold}" "${normal}"; else printf "111"; fi; printf "  : Kernel upgrade.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "112" ]]; then printf "%s%s112%s" "${rev}" "${bold}" "${normal}"; else printf "112"; fi; printf "  : Repositories update.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "113" ]]; then printf "%s%s113%s" "${rev}" "${bold}" "${normal}"; else printf "113"; fi; printf "  : Repositories upgrade.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "121" ]]; then printf "%s%s121%s" "${rev}" "${bold}" "${normal}"; else printf "121"; fi; printf "  : Install the base utilites and applications.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "122" ]]; then printf "%s%s122%s" "${rev}" "${bold}" "${normal}"; else printf "122"; fi; printf "  : Install all my Universe application.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "125" ]]; then printf "%s%s125%s" "${rev}" "${bold}" "${normal}"; else printf "125"; fi; printf "  : Flatpak install and configure.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "131" ]]; then printf "%s%s131%s" "${rev}" "${bold}" "${normal}"; else printf "131"; fi; printf "  : Setup the home directories to link to the data disk directories.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "141" ]]; then printf "%s%s141%s" "${rev}" "${bold}" "${normal}"; else printf "141"; fi; printf "  : Install KDE Desktop from backports.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "142" ]]; then printf "%s%s142%s" "${rev}" "${bold}" "${normal}"; else printf "142"; fi; printf "  : Upgrade KDE to Beta KDE on backports.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "151" ]]; then printf "%s%s151%s" "${rev}" "${bold}" "${normal}"; else printf "151"; fi; printf "  : Install Gnome Desktop from backports.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "152" ]]; then printf "%s%s152%s" "${rev}" "${bold}" "${normal}"; else printf "152"; fi; printf "  : Change Gnome desktop settings.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "161" ]]; then printf "%s%s161%s" "${rev}" "${bold}" "${normal}"; else printf "161"; fi; printf "  : ownCloudClient.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "162" ]]; then printf "%s%s162%s" "${rev}" "${bold}" "${normal}"; else printf "162"; fi; printf "  : Dropbox.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "163" ]]; then printf "%s%s163%s" "${rev}" "${bold}" "${normal}"; else printf "163"; fi; printf "  : inSync for GoogleDrive.\n"
    printf "\n"
    printf "     a    : Utilities Menu.\n"
    printf "     b    : Internet and eMail Menu.\n"
    printf "     c    : Applications Menu.\n"
    printf "     d    : Development Apps and IDEs Menu.\n"
    printf "     e    : Photography and Imaging Menu.\n"
    printf "     f    : Virtualization Applictions Menu.\n"
    printf "     g    : Other (Hardware Drivers, ).\n"
    printf "     h    : Buildman Settings, Utilities and tests.\n"
    printf "     x    : Clear selections.\n"
    printf "\n"
    printf "\n"
    printf "     %s1   : RUN%s\n" "${bold}" "${normal}"
    printf "\n"
    printf "    0/q   : Return to main menu\n\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\n\n"
    fi
  }

  submenuUtils(){
    clear
    printf "\n\n"
    printf "  %s%sUtilities%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "211" ]]; then printf "%s%s211%s" "${rev}" "${bold}" "${normal}"; else printf "211"; fi; printf "  : Latte Dock.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "212" ]]; then printf "%s%s212%s" "${rev}" "${bold}" "${normal}"; else printf "212"; fi; printf "  : Doublecmd.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "213" ]]; then printf "%s%s213%s" "${rev}" "${bold}" "${normal}"; else printf "213"; fi; printf "  : FreeFileSync.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "221" ]]; then printf "%s%s221%s" "${rev}" "${bold}" "${normal}"; else printf "221"; fi; printf "  : Powerline.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "231" ]]; then printf "%s%s231%s" "${rev}" "${bold}" "${normal}"; else printf "231"; fi; printf "  : Bitwarden Password Manager.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "241" ]]; then printf "%s%s241%s" "${rev}" "${bold}" "${normal}"; else printf "241"; fi; printf "  : Stacer Linux System Optimizer and Monitoring.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "251" ]]; then printf "%s%s251%s" "${rev}" "${bold}" "${normal}"; else printf "251"; fi; printf "  : Etcher USB loader.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "261" ]]; then printf "%s%s261%s" "${rev}" "${bold}" "${normal}"; else printf "261"; fi; printf "  : UNetbootin ISO to USB Application.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "271" ]]; then printf "%s%s271%s" "${rev}" "${bold}" "${normal}"; else printf "271"; fi; printf "  : Y-PPA Manager.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "272" ]]; then printf "%s%s272%s" "${rev}" "${bold}" "${normal}"; else printf "272"; fi; printf "  : Boot Repair Appliction.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "281" ]]; then printf "%s%s281%s" "${rev}" "${bold}" "${normal}"; else printf "281"; fi; printf "  : rEFInd Boot Manager.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "291" ]]; then printf "%s%s291%s" "${rev}" "${bold}" "${normal}"; else printf "291"; fi; printf "  : Install extra fonts.\n"
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

  submenuInternet(){
    clear
    printf "\n\n"
    printf "  %s%sInternet and eMail%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "311" ]]; then printf "%s%s311%s" "${rev}" "${bold}" "${normal}"; else printf "311"; fi; printf "  : Google Chrome browser.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "312" ]]; then printf "%s%s312%s" "${rev}" "${bold}" "${normal}"; else printf "312"; fi; printf "  : Opera Browser.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "321" ]]; then printf "%s%s321%s" "${rev}" "${bold}" "${normal}"; else printf "321"; fi; printf "  : Thunderbird email client.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "323" ]]; then printf "%s%s323%s" "${rev}" "${bold}" "${normal}"; else printf "323"; fi; printf "  : Mailspring desktop email client.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "324" ]]; then printf "%s%s324%s" "${rev}" "${bold}" "${normal}"; else printf "324"; fi; printf "  : Evolution email client.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "331" ]]; then printf "%s%s331%s" "${rev}" "${bold}" "${normal}"; else printf "331"; fi; printf "  : Skype.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "341" ]]; then printf "%s%s341%s" "${rev}" "${bold}" "${normal}"; else printf "341"; fi; printf "  : Winds RSS Reader and Podcast application.\n"

    printf "    0/q  : Return to Selection menu\n\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\n\n"
    fi
  }

  submenuApps(){
    clear
    printf "\n\n"
    printf "  %s%sApplications%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "441" ]]; then printf "%s%s441%s" "${rev}" "${bold}" "${normal}"; else printf "441"; fi; printf "  : Calibre.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "451" ]]; then printf "%s%s451%s" "${rev}" "${bold}" "${normal}"; else printf "451"; fi; printf "  : Anbox.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "461" ]]; then printf "%s%s461%s" "${rev}" "${bold}" "${normal}"; else printf "461"; fi; printf "  : LibreCAD.\n"
    printf "    0/q  : Return to Selection menu\n\n"

    if [[ ! $1 = "SelectItem" ]]; then
      printf "Current Selection is: "
      for i in "${menuSelections[@]}"; do
        printf "%s, " "${i}"
      done
      printf "\n\n"
    fi
  }

  submenuDev(){
    clear
    printf "\n\n"
    printf "  %s%sDevelopment applications and IDEs%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "511" ]]; then printf "%s%s511%s" "${rev}" "${bold}" "${normal}"; else printf "511"; fi; printf "  : Install Development Apps and IDEs.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "512" ]]; then printf "%s%s512%s" "${rev}" "${bold}" "${normal}"; else printf "512"; fi; printf "  : Git.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "521" ]]; then printf "%s%s521%s" "${rev}" "${bold}" "${normal}"; else printf "521"; fi; printf "  : Bashdb.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "522" ]]; then printf "%s%s522%s" "${rev}" "${bold}" "${normal}"; else printf "522"; fi; printf "  : PyCharm IDE.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "523" ]]; then printf "%s%s523%s" "${rev}" "${bold}" "${normal}"; else printf "523"; fi; printf "  : Visual Studio Code.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "524" ]]; then printf "%s%s524%s" "${rev}" "${bold}" "${normal}"; else printf "524"; fi; printf "  : Brackets IDE.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "531" ]]; then printf "%s%s531%s" "${rev}" "${bold}" "${normal}"; else printf "531"; fi; printf "  : Postman.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "541" ]]; then printf "%s%s541%s" "${rev}" "${bold}" "${normal}"; else printf "541"; fi; printf "  : AsciiDoc.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "551" ]]; then printf "%s%s551%s" "${rev}" "${bold}" "${normal}"; else printf "551"; fi; printf "  : Oracle Java Latest.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "552" ]]; then printf "%s%s552%s" "${rev}" "${bold}" "${normal}"; else printf "552"; fi; printf "  : Oracle Java 8.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "553" ]]; then printf "%s%s553%s" "${rev}" "${bold}" "${normal}"; else printf "553"; fi; printf "  : Oracle Java 9.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "591" ]]; then printf "%s%s591%s" "${rev}" "${bold}" "${normal}"; else printf "591"; fi; printf "  : Ruby Repo.\n"
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

  submenuPhoto(){
    clear
    printf "\n\n"
    printf "  %s%sPhoto and Imaging Applications%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "611" ]]; then printf "%s%s611%s" "${rev}" "${bold}" "${normal}"; else printf "611"; fi; printf "  : Photography Apps.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "612" ]]; then printf "%s%s612%s" "${rev}" "${bold}" "${normal}"; else printf "612"; fi; printf "  : Variety.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "621" ]]; then printf "%s%s621%s" "${rev}" "${bold}" "${normal}"; else printf "621"; fi; printf "  : Digikam.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "622" ]]; then printf "%s%s622%s" "${rev}" "${bold}" "${normal}"; else printf "622"; fi; printf "  : Darktable.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "631" ]]; then printf "%s%s631%s" "${rev}" "${bold}" "${normal}"; else printf "631"; fi; printf "  : RapidPhotoDownloader.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "641" ]]; then printf "%s%s641%s" "${rev}" "${bold}" "${normal}"; else printf "641"; fi; printf "  : Image Editing Applications.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "651" ]]; then printf "%s%s651%s" "${rev}" "${bold}" "${normal}"; else printf "651"; fi; printf "  : Inkscape.\n"
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

  submenuMedia(){
    clear
    printf "\n\n"
    printf "  %s%sAudio, Video and Media Applications%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "711" ]]; then printf "%s%s711%s" "${rev}" "${bold}" "${normal}"; else printf "711"; fi; printf "  : Music and Video Applications.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "713" ]]; then printf "%s%s713%s" "${rev}" "${bold}" "${normal}"; else printf "713"; fi; printf "  : Spotify.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "712" ]]; then printf "%s%s712%s" "${rev}" "${bold}" "${normal}"; else printf "712"; fi; printf "  : Google Play Music Desktop Player.\n"
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

  submenuVirtualization(){
    clear
    printf "\n\n"
    printf "  %s%Virtualization%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "811" ]]; then printf "%s%s811%s" "${rev}" "${bold}" "${normal}"; else printf "811"; fi; printf "  : Docker.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "821" ]]; then printf "%s%s821%s" "${rev}" "${bold}" "${normal}"; else printf "821"; fi; printf "  : Setup for a VirtualBox guest.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "822" ]]; then printf "%s%s822%s" "${rev}" "${bold}" "${normal}"; else printf "822"; fi; printf "  : VirtualBox Host.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "831" ]]; then printf "%s%s831%s" "${rev}" "${bold}" "${normal}"; else printf "831"; fi; printf "  : Setup for a Vmware guest.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "851" ]]; then printf "%s%s851%s" "${rev}" "${bold}" "${normal}"; else printf "851"; fi; printf "  : Vagrant.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "881" ]]; then printf "%s%s881%s" "${rev}" "${bold}" "${normal}"; else printf "881"; fi; printf "  : KVM.\n"
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

  submenuOther(){
    clear
    printf "\n\n"
    printf "  %s%Hardware Drivers%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "911" ]]; then printf "%s%s911%s" "${rev}" "${bold}" "${normal}"; else printf "911"; fi; printf "  : Laptop Display Drivers for Intel en Nvidia.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "921" ]]; then printf "%s%s921%s" "${rev}" "${bold}" "${normal}"; else printf "921"; fi; printf "  : DisplayLink.\n"
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

  submenuSettings(){
    clear
    printf "\n\n"
    printf "  %s%sBuildman Settings%s\n\n" "${bold}" "${rev}" "${normal}"
    case $typeOfRun in
      SelectThenAutoRun )
        printf "  Select items and then install the items without prompting.\n"
      ;;
      SelectThenStepRun )
        printf "  Select items and then install the items each with a prompt.\n"
      ;;
      SelectItem )
        printf "  Select items and for individual installation with prompt.\n"
      ;;
    esac
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "191" ]]; then printf "%s%s191%s" "${rev}" "${bold}" "${normal}"; else printf "191"; fi; printf "  : Set options for an Ubuntu Beta install with PPA references to a previous version.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "132" ]]; then printf "%s%s132%s" "${rev}" "${bold}" "${normal}"; else printf "132"; fi; printf "  : Create test data directories on data drive.\n"
    printf "     ";if [[ "${menuSelections[*]}" =~ "2" ]]; then printf "%s%s2%s" "${rev}" "${bold}" "${normal}"; else printf "2"; fi; printf "  : Questions asked is "; if [[ "$noPrompt" = 1 ]]; then printf "%s%sOFF%s" "${rev}" "${bold}" "${normal}"; else printf "%s%sON%s" "${rev}" "$bold" "$normal"; fi; printf ". Select 2 to toggle so that questions is "; if [[ "$noPrompt" = 1 ]]; then printf "%sASKED%s" "${bold}" "${normal}"; else printf "%sNOT ASKED%s" "${bold}" "${normal}"; fi; printf ".\n";
    printf "     ";if [[ "${menuSelections[*]}" =~ "3" ]]; then printf "%s%s3%s" "${rev}" "${bold}" "${normal}"; else printf "3"; fi; printf "  : noCurrentReleaseRepo is "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%s%sON%s" "${rev}" "${bold}" "${normal}"; else printf "%sOFF%s" "$bold" "$normal"; fi; printf ". Select 3 to toggle noCurrentReleaseRepo to "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%sOFF%s" "${bold}" "${normal}"; else printf "%sON%s" "${bold}" "${normal}"; fi; printf ".\n";
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
    printf "\n"
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
            printf "\n"
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
            printf "\n"
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
            printf "\n"
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
            printf "\n"
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
            printf "\n"
            if ((600<=choiceOpt && choiceOpt<=699))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        e )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuMedia "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\n"
            if ((700<=choiceOpt && choiceOpt<=799))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        f )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuVirtualization "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\n"
            if ((800<=choiceOpt && choiceOpt<=899))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        g )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuOther "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\n"
            if ((911<=choiceOpt && choiceOpt<=999))
            then
              howToRun "$choiceOpt" "$typeOfRun"
            fi
          done
          choiceOpt=NULL
        ;;
        s )
          until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
            submenuSettings "$typeOfRun"
            read -rp "Enter your choice : " choiceOpt
            printf "\n"
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
    125 ) asking flatpakInstall "Install Flatpak and configure Flatpak Repos" "Flatpak Install and Flatpak Repos Complete." ;;
    121 ) asking installBaseApps "Install the base utilities and applications" "Base Utilities and applications install complete." ;;
    122 ) asking installUniverseApps "Install all my Universe applications" "Universe applications install complete." ;;
    131 ) asking dataDirLinksSetup "Setup the home directories to link to the data disk directories" "Setup of the home directories to link to the data disk directories complete." ;;
    141 ) asking kdeBackportsApps "Install KDE Desktop from backports" "Installation of the KDE Backport Desktop complete." ;;
    142 ) asking kdeBetaBackportsRepo "Upgrae KDE repo to Beta KDE Repo on backports" "Upgrae of the KDE Beta repo complete." ;;
    151 ) asking gnome3Backports "Install Gnome Desktop from backports" "Gnome Desktop install from backports complete." ;;
    152 ) asking gnome3Settings "run Gnome settings" "Gnome Settings done." ;;
    161 ) asking ownCloudClientInstallApp "install ownCloud client" "ownCloud Client install complete." ;;
    811 ) asking dockerInstall "install Docker" "Docker install complete." ;;
    162 ) asking dropboxInstall "install Dropbox"  "Dropbox install complete." ;;
    163 ) asking insyncInstall  "install inSync for GoogleDrive" "inSync for GoogleDrive install complete." ;;
    321 ) asking thunderbirdInstall  "install Thunderbird email client" "Thunderbird email client install complete." ;;
    324 ) asking evolutionInstall  "install Evolution email client" "Evolution email client install complete." ;;
    323 ) asking mailspringInstall  "install Mailspring desktop email client" "Mailspring desktop email client install complete." ;;
    341 ) asking windsInstall  "install Winds RSS Reader and Podcast application" "Winds RSS Reader and Podcast application install complete." ;;
    331 ) asking skypeInstall  "install Skype" "Skype install complete." ;;
    311 ) asking googleChromeInstall "Install Google Chrome browser" "Google Chrome browser install complete." ;;
    212 ) asking  doublecmdInstall "Install Doublecmd" "Doublecmd install complete." ;;
    211 ) asking latteDockInstall "Install Latte Dock" "Latte Dock install complete." ;;
    213 ) asking FreeFileSyncInstall "install FreeFileSync" "FreeFileSync install complete." ;;
    461 ) asking librecadInstall "instal LibreCAD" "LibreCAD install complete." ;;
    441 ) asking calibreInstall "install Calibre" "Calibre install complete." ;;
    271 ) asking yppaManagerInstall "install Y-PPA Manager" "Y-PPA Manager install complete." ;;
    291 ) asking fontsInstall "install extra fonts" "Extra fonts install complete." ;;
    312 ) asking operaInstall "install Opera browser" "Opera browser install complete." ;;
    272 ) asking bootRepairInstall "install Boot Repair" "Boot Repair install complete." ;;
    281 ) asking rEFIndInstall "install rEFInd Boot Manager" "rEFInd Boot Manager install complete." ;;
    261 ) asking unetbootinInstall "install UNetbootin" "UNetbootin install complete." ;;
    251 ) asking etcherInstall "install Etcher USB Loader" "Etcher USB Loader install complete." ;;
    241 ) asking stacerInstall "install Stacer Linux System Optimizer and Monitoring" "Stacer Linux System Optimizer and Monitoring install complete." ;;
    231 ) asking bitwardenInstall "install Bitwarden Password Manager" "Bitwarden Password Manager install complete." ;;
    511 ) asking devAppsInstall "install Development Apps and IDEs" "Development Apps and IDEs install complete." ;;
    512 ) asking gitInstall "install Git" "Git install complete." ;;
    541 ) asking asciiDocInstall "install AsciiDoc" "AsciiDoc install complete." ;;
    521 ) asking bashdbInstall "install Bashdb" "Bashdb install complete." ;;
    522 ) asking pycharmInstall "Install PyCharm" "PyCharm install complete." ;;
    523 ) asking vscodeInstall "Install Visual Studio Code" "Visual Studio Code install complete." ;;
    524 ) asking bracketsInstall "Install Brackets" "Brackets install complete." ;;
    531 ) asking postmanInstall "Install Postman" "Postman install complete." ;;
    591 ) asking rubyRepo "add the Ruby Repositories" "Ruby Repositories added." ;;
    552 ) asking oracleJava8Install "Install Oracle Java 8" "Oracle Java 8 install complete." ;;
    553 ) asking oracleJava9Install "Install Oracle Java 9" "Oracle Java 9 install complete." ;;
    551 ) asking oracleJavaLatestInstall "Install Oracle Java Latest" "Oracle Java Latest install complete." ;;
    611 ) asking photoAppsInstall "install Photography Apps" "Photography Apps install complete." ;;
    621 ) asking digikamInstall "install Digikam" "DigiKam install complete." ;;
    622 ) asking darktableInstall "install Darktable" "Darktable install complete." ;;
    631 ) asking rapidPhotoDownloaderInstall "install rapidPhotoDownloader" "rapidPhotoDownloader install complete." ;;
    641 ) asking imageEditingAppsInstall  "install Image Editing Applications" "Image Editing Applications installed." ;;
    711 ) asking musicVideoAppsInstall "install Music and Video Applications" "Music and Video Applications installed." ;;
    713 ) asking spotifyInstall "install Spotify" "Spotify installed." ;;
    712 ) asking google-play-music-desktop-playerInstall "install Google Play Music Desktop Player" "Google Play Music Desktop Player installed." ;;
    651 ) asking inkscapeInstall "install Inkscape" "Inkscape installed." ;;
    612 ) asking varietyInstall "install Variety" "Variety installed." ;;
    821 ) asking virtualboxGuestSetup "Setup and install VirtualBox guest" "VirtaulBox Guest install complete." ;;
    822 ) asking virtualboxHostInstall "Install VirtualBox Host" "VirtualBox Host install complete." ;;
    831 ) asking vmwareGuestSetup "Setup for a Vmware guest" "Vmware Guest setup complete." ;;
    851 ) asking vagrantInstall "install Vagrant" "Vagrant install complete." ;;
    881 ) asking kvmInstall "install KVM" "KVM install complete." ;;
    911 ) asking laptopDisplayDrivers "Laptop Display Drivers for Intel en Nvidia" "Laptop Display Drivers for Intel en Nvidia install complete." ;;
    921 ) asking displayLinkInstallApp "install DisplayLink" "DisplayLink install complete." ;;
    191 ) asking setUbuntuVersionParameters "Set options for an Ubuntu Beta install with PPA references to another version." "Set Ubuntu Version Complete" ;;
    132 ) asking createTestDataDirs "Create test data directories on data drive." "Test data directories on data drive created." ;;
    221 ) asking powerlineInstall "install Powerline" "Powerline install complete." ;;
    451 ) asking anboxInstall "install Anbox" "Anbox install complete." ;;
    2)
      if [[ $noPrompt = 0 ]]; then
        noPrompt=1
        println_blue "Questions asked is OFF.\n No questions will be asked."
        log_debug "Questions asked is OFF.\n No questions will be asked."
      else
        noPrompt=0
        println_blue "Questions asked is ON.\n All questions will be asked."
        log_debug "Questions asked is ON.\n All questions will be asked."
      fi
    ;;
    3)
      if [[ $noCurrentReleaseRepo = 0 ]]; then
        noCurrentReleaseRepo=1
        println_blue "noCurrentReleaseRepo ON.\n The repos will be installed against ${previousStableReleaseName}."
        log_debug "noCurrentReleaseRepo ON.\n The repos will be installed against ${previousStableReleaseName}."
      else
        noCurrentReleaseRepo=0
        println_blue "noCurrentReleaseRepo OFF.\n The repos will be installed against ${distReleaseName}."
        log_debug "noCurrentReleaseRepo OFF.\n The repos will be installed against ${distReleaseName}."
      fi
    ;;
  esac
}

selectDesktopEnvironment(){
  clear
  until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
    printf "\n\n"
    printf "  Desktop Environment is: %s%s%s%s\n\n" "${bold}" "${yellow}" "${desktopEnvironment}" "${normal}"
    printf "
    There are the following desktop environment options
    TASK : DESCRIPTION
    -----: ---------------------------------------\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "gnome" ]]; then printf "%s%s1%s" "${rev}" "${bold}" "${normal}"; else printf "1"; fi; printf "   : Set desktop environment as gnome.\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "kde" ]]; then printf "%s%s2%s" "${rev}" "${bold}" "${normal}"; else printf "2"; fi; printf "   : Set desktop environment as KDE.\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "ubuntu" ]]; then printf "%s%s3%s" "${rev}" "${bold}" "${normal}"; else printf "3"; fi; printf "   : Set desktop environment as Ubuntu Unity.\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "xubuntu" ]]; then printf "%s%s4%s" "${rev}" "${bold}" "${normal}"; else printf "4"; fi; printf "   : Set desktop environment as XFCE (Xubuntu).\n"
    printf "     ";if [[ "${desktopEnvironment}" =~ "lubuntu" ]]; then printf "%s%s5%s" "${rev}" "${bold}" "${normal}"; else printf "5"; fi; printf "   : Set desktop environment as LXDE (Lubuntu).\n"
    printf "\n"
    printf "    0/q  : Return to Selection menu\n\n"

    read -rp "Enter your choice : " choiceOpt
    printf "\n"
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
      println_red "\nPlease enter a valid choice from 1-5.\n"
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
    println_info "\n"
    println_info "BuildMan                                                    "
    println_info "====================================================================="

    # printf \n    MESSAGE : In case of options, one value is displayed as the default value.\n"
    # printf "    Do erase it to use other value.\n"

    printf "\n    BuildMan %s\n" $buildmanVersion
    printf "\n    This script is documented in README.md file.\n"
    printf "\n    Running: "
    println_yellow "${distReleaseName} ${distReleaseVer} ${desktopEnvironment}\n"
    printf "\n    There are the following options for this script\n"
    printf "\n    TASK :     DESCRIPTION\n\n"
    printf "    1    : Questions asked is "; if [[ "$noPrompt" = 1 ]]; then printf "%s%sOFF%s" "$bold" "$green" "$normal"; else printf "%s%s%sON%s" "$rev" "$bold" "$red" "$normal"; fi; printf ".\n"
    printf "            Select 1 to toggle so that questions are "; if [[ "$noPrompt" = 1 ]]; then printf "%sASKED%s" "${bold}" "${normal}"; else printf "%sNOT ASKED%s" "${bold}" "${normal}"; fi; printf ".\n";
    printf "    2    : Change to older Release Repositories is "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%s%s%sON%s" "${rev}" "${bold}" "${red}" "${normal}"; else printf "%s%sOFF%s" "$bold" "${green}" "$normal"; fi; printf ".\n"
    printf "            Select 2 to toggle older Release Repositories to "; if [[ "$noCurrentReleaseRepo" = 1 ]]; then printf "%sOFF%s" "${bold}" "${normal}"; else printf "%sON%s" "${bold}" "${normal}"; fi; printf ".\n";
    printf "    3    : Install on a Beta version is "; if [[ "$betaAns" = 1 ]]; then printf "%s%s%sON%s" "${rev}" "${bold}" "${red}" "${normal}"; else printf "%s%sOFF%s" "$bold" "${green}" "$normal"; fi; printf ".\n"
    printf "            Select 3 to toggle the install for a beta version to "; if [[ "$betaAns" = 1 ]]; then printf "%sOFF%s" "${bold}" "${normal}"; else printf "%sON%s" "${bold}" "${normal}"; fi; printf ".\n";
    printf "    4    : Identified Desktop is %s%s%s%s. Select 4 to change.\n" "${yellow}" "${bold}" "$desktopEnvironment" "${normal}"
    printf "    5    : Add user %s%s%s to sudoers.\n\n" "$bold" "$USER" "$normal"
    printf "    6    : Select the applications and then run uninterupted.
    7    : Select the applications and then run each item individually
    8    : Install applications from the menu one by one.

    10   : Install Laptop with pre-selected applications
    11   : Install Workstation with pre-selected applications
    12   : Install a Virtual Machine with pre-selected applications

    15   : Run a VirtualBox full test run, all apps.

    0/q  : Quit this program

    "
    printf "Enter your system password if asked...\n\n"

    read -rp "Enter your choice : " choiceMain
    printf "\n"

    # if [[ $choiceMain == 'q' ]]; then
    # 	exit 0
    # fi


    # take inputs and perform as necessary
    case "$choiceMain" in
      1)
        if [[ $noPrompt = 0 ]]; then
          noPrompt=1
          println_blue "Questions asked is OFF.\n No questions will be asked."
          log_debug "Questions asked is OFF.\n No questions will be asked."
        else
          noPrompt=0
          println_blue "Questions asked is ON.\n All questions will be asked."
          log_debug "Questions asked is ON.\n All questions will be asked."
        fi
      ;;
      2)
        if [[ $noCurrentReleaseRepo = 0 ]]; then
          noCurrentReleaseRepo=1
          println_blue "Using older repositories ON.\n The repos will be installed against ${previousStableReleaseName}."
          log_debug "Using older repositories ON.\n The repos will be installed against ${previousStableReleaseName}."
        else
          noCurrentReleaseRepo=0
          println_blue "Using older repositories OFF.\n The repos will be installed against ${distReleaseName}."
          log_debug "Using older repositories OFF.\n The repos will be installed against ${distReleaseName}."
        fi
      ;;
      3)
        if [[ $betaAns = 0 ]]; then
          betaAns=1
          println_blue "Beta release is ON.\n The repos will be installed against ${stableReleaseName}."
          log_debug "Beta release is ON.\n The repos will be installed against ${stableReleaseName}."
        else
          betaAns=0
          println_blue "Beta release is OFF.\n The repos will be installed against ${distReleaseName}."
          log_debug "Beta release is OFF.\n The repos will be installed against ${distReleaseName}."
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
        menuSelectionsInput=(111 112 113 125 121 122 161 811 162 163 321 323 341 331 311 212 441 291 271 272 261 251 241 231 511 512 541 521 541 611 622 631 641 711 713 712 651 612 822 881 851)
        case $desktopEnvironment in
          gnome )
            menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
          kde )
            menuSelectionsInput+=(141 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated installation for a Laptop\n"
          menuRun "SelectThenAutoRun" "${menuSelectionsInput[@]}"
          pressEnterToContinue "Automated installation for a Laptop completed successfully."
        else
          println_info "Step install for a Laptop\n"
          menuRun "SelectThenStepRun" "${menuSelectionsInput[@]}"
          pressEnterToContinue "Automated installation for a Laptop completed successfully."
        fi
      ;;
      11 )
        # Install Workstation with pre-selected applications
        menuSelectionsInput=(111 112 113 125 121 122 161 811 162 163 321 323 341 331 311 212 441 291 271 272 261 251 241 231 511 512 541 521 541 611 622 631 641 711 713 712 651 612 822 881 851)
        case $desktopEnvironment in
          gnome )
            menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
          kde )
            menuSelectionsInput+=(141 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated installation for a Workstation\n"
          menuRun "SelectThenAutoRun" "${menuSelectionsInput[@]}"
          pressEnterToContinue "Automated installation for a Workstation completed successfully."
        else
          println_info "Step select installation for a Workstation.\n"
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
            menuSelectionsInput+=(141 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated install for a virtual machine\n"
          menuRun "AutoRun" "${menuSelectionsInput[@]}"
          println_info "Virtual machine automated install completed."
        else
          println_info "Step install for a virtual machine\n"
          menuRun "SelectThenStepRun" "${menuSelectionsInput[@]}"
          println_info "Virtual machine step install completed."
        fi
      ;;
      15 )
        # Run a VirtualBox full test run, all apps.
        menuSelectionsInput=(131 111 112 113 125 121 122 141 142 151 152 161 811 162 163 321 324 323 341 331 311 212 213 461 441 291 271 312 272 281 261 251 241 231 511 512 541 521 541 523 524 531 591 552 551 611 621 622 631 641 711 713 712 651 612 881 851 221 451)
        case $desktopEnvironment in
          gnome )
            menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
          kde )
            menuSelectionsInput+=(141 142 211 621)  #: Install KDE Desktop from backports #: Digikam
          ;;
          ubuntu )
            # menuSelectionsInput+=(151 152)    #: Install Gnome Desktop from backports #: Install Gnome Desktop from backports
          ;;
        esac
        menuSelectionsInput+=(112 113)
        if [[ $noPrompt = 1 ]]; then
          println_info "Automated Test install all apps on a VirtualBox VM\n"
          menuRun "SelectThenAutoRun" "${menuSelectionsInput[@]}"
          println_info "All apps on VirtualBox automated install completed."
        else
          println_info "Step Test install all apps on a VirtualBox VM\n"
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
  log_info "\nStart of BuildMan"
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

printf "\n\nJob done!\n"
printf "Thanks for using. :-)\n"
# ############################################################################
# set debugging off
# set -xv
exit;
