#!/bin/bash

# DateVer 2018/06/12
# Buildman V2.0
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
  betaReleaseName="cosmic"
  betaReleaseVer="18.10"
  stableReleaseName="bionic"
  stableReleaseVer="18.04"
  previousStableReleaseName="artful"
  noCurrentReleaseRepo=0

  ltsReleaseName="bionic"
  desktopEnvironment=""
  kernelRelease=$(uname -r)
  distReleaseVer=$(lsb_release -sr)
  distReleaseName=$(lsb_release -sc)
  noPrompt=0
  debugLogFile="buildman.log"
  errorLogFile="buildman_error.log"

  mkdir -p "$HOME/tmp"
  sudo chown "$USER":"$USER" "$HOME/tmp"
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
    \033[1;31m###############################################################\n\033[0m\n" >>$debugLogFile
  else
    touch $debugLogFile
  fi
  if [[ -e $errorLogFile ]]; then
    echo -en "\n \033[1;31m##############################################################\n\033[0m
    \n
    \033[1;31m START OF NEW RUN\n\033[0m
    \n
    \033[1;31m###############################################################\n\033[0m\n" >>$errorLogFile
    echo -en "\n" >>$errorLogFile
  else
    touch $errorLogFile
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
    printf "DEBUG: %q\n" "$@" >>$debugLogFile 2>>$errorLogFile
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
      echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}" >>$debugLogFile 2>>$errorLogFile
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


# ############################################################################
# Die process to exit because of a failure
die() { echo "$*" >&2; exit 1; }

pressEnterToContinue() {
  if [[ "$noPrompt" -ne 1 ]]; then
    read -rp "$1 Press ENTER to continue." nullEntry
    printf "%s" "$nullEntry"
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
    "ubuntu:GNOME" )
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
  pressEnterToContinue "Repo Update Finished."
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
  sudo apt autoremove -y;
  # sudo apt clean -y
  pressEnterToContinue "Repo Upgrade finished."
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                         Kernel                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Setup Kernel
kernelUprade () {
  log_info "Kernel Upgrade"
  println_banner_yellow "Kernel Upgrade                                                        "
  # if [[ "$noPrompt" -ne 1 ]]; then
  #   read -rp "Do you want to go ahead with the kernel and packages Upgrade, and possibly will have to reboot (y/n)?" answer
  # else
  #   answer=1
  # fi
  read -rp "Do you want to go ahead with the kernel and packages Upgrade, and possibly will have to reboot (y/n)?" answer
  if [[ $answer = [Yy1] ]]; then
    repoUpdate
    sudo apt install -yf build-essential linux-headers-"$kernelRelease" linux-image-extra-"$kernelRelease" linux-signed-image-"$kernelRelease" linux-image-extra-virtual;
    sudo apt upgrade -y;
    sudo apt full-upgrade -y;
    sudo apt dist-upgrade -y;
    pressEnterToContinue "Kernel Upgrades installed."
    # if [[ "$noPrompt" -ne 1 ]]; then
    #   read -rp "Do you want to reboot (y/n)?" answer
    #   if [[ $answer = [Yy1] ]]; then
    #     sudo reboot
    #   fi
    # fi
    read -rp "Do you want to reboot (y/n)?" answer
    if [[ $answer = [Yy1] ]]; then
      sudo reboot
    fi
  fi
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

  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

  sudo sh -c "echo 'deb https://download.virtualbox.org/virtualbox/debian $distReleaseName contrib' >> /etc/apt/sources.list.d/virtualbox-$distReleaseName.list"


  if [[ $betaAns == 1 ]] || [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Beta Code or no new repo, downgrade the apt sources."
    println_red "Beta Code or no new repo, downgrade the apt sources."
    changeAptSource "/etc/apt/sources.list.d/virtualbox-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi

  repoUpdate
  # VirtualBox 5.1
  # sudo apt install virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso virtualbox-qt vde2 vde2-cryptcab qemu qemu-user-static qemu-efi openbios-ppc openhackware dkms
  #VirtualBox 5.2
  sudo apt install virtualbox-5.2 virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso vde2 vde2-cryptcab qemu qemu-user-static qemu-efi openbios-ppc openhackware dkms
  # case $desktopEnvironment in
  #   "kde" )
  #   # sudo apt install -y virtualbox-qt;
  #   ;;
  # esac


  # LINE1="192.168.56.1:/home/juanb/      $HOME/hostfiles/home    nfs     rw,intr    0       0"
  # sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  # LINE2="192.168.56.1:/data      $HOME/hostfiles/data    nfs     rw,intr    0       0"
  # sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  # sudo mount -a
  pressEnterToContinue "VirtualBox Host installed."
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
  pressEnterToContinue "VirtaulBox Guest Additions installed."
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                     Home directory setup                                 O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Create directories on data disk for testing
createTestDataDirs () {
  log_info "XPS Data Dir links"
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
        log_debug "Remove directory $HOME/data"
        rm -R "${HOME/$sourceDataDirectory:?}"
        ln -s "/data" "$HOME/$sourceDataDirectory"
      fi
    else
      log_debug "Link directory $HOME/data"
      ln -s "/data" "$HOME/$sourceDataDirectory"
    fi

    linkDataDirectories=(
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
      log_debug "Link directory = $sourceLinkDirectory"
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
      # remove after testing
      mkdir -p "/data/$sourceLinkDirectory"
      # up to here
    done
  fi
  pressEnterToContinue "Test Data Directories created."
}

# ############################################################################
# Links directories to data disk if exists
dataDirLinksSetup () {
  log_info "XPS Data Dir links"
	currentPath=$(pwd)
  cd "$HOME" || exit


  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    if [ -d "$HOME/$sourceDataDirectory" ]; then
      if [ -L "$HOME/$sourceDataDirectory" ]; then
        # It is a symlink!
        log_info "Keep symlink $HOME/data"
        # log_warning "Remove symlink $HOME/data"
        # rm "$HOME/$sourceDataDirectory"
        # ln -s "/data" "$HOME/$sourceDataDirectory"
      else
        # It's a directory!
        log_debug "Remove directory $HOME/data"
        rm -R "${HOME/$sourceDataDirectory:?}"
        ln -s "/data" "$HOME/$sourceDataDirectory"
      fi
    else
      log_debug "Link directory $HOME/data"
      ln -s "/data" "$HOME/$sourceDataDirectory"
    fi

    linkDataDirectories=(
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
    "bin"
    )

    log_info "linkDataDirectories ${linkDataDirectories[*]}"

    for sourceLinkDirectory in "${linkDataDirectories[@]}"; do
      log_debug "Link directory = $sourceLinkDirectory"
      # remove after testing
      # mkdir -p "/data/$sourceLinkDirectory"
      # up to here
      if [ -e "$HOME/$sourceLinkDirectory" ]; then
        if [ -d "$HOME/$sourceLinkDirectory" ]; then
          if [ -L "$HOME/$sourceLinkDirectory" ]; then
            # It is a symlink!
            log_debug "Remove symlink $HOME/$sourceLinkDirectory"
            rm "$HOME/$sourceLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
            log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          else
            # It's a directory!
            log_debug "Remove directory $HOME/data"
            rmdir "$HOME/$sourceLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
            log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          fi
        else
          rm "$HOME/$sourceLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
        fi
      else
        log_debug "$HOME/$sourceLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOME/$sourceLinkDirectory" ];  then
          # It is a symlink!
          log_debug "Remove symlink $HOME/$sourceLinkDirectory"
          rm "$HOME/$sourceLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
          log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
        fi
        ln -s "/data/$sourceLinkDirectory" "$HOME/$sourceLinkDirectory"
        log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
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
      log_debug "sourceLinkDirectoryLink directory = $sourceLinkDirectory; targetLinkDirectory = $targetLinkDirectory"
      if [ -e "$HOME/$targetLinkDirectory" ]; then
        if [ -d "$HOME/$targetLinkDirectory" ]; then
          if [ -L "$HOME/$targetLinkDirectory" ]; then
            # It is a symlink!
            log_debug "Remove symlink $HOME/$targetLinkDirectory"
            rm "$HOME/$targetLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
            log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          else
            # It's a directory!
            log_debug "Remove directory $HOME/data"
            rmdir "$HOME/$targetLinkDirectory"
            ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
            log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          fi
        else
          rm "$HOME/$targetLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
        fi
      else
        log_debug "$HOME/$targetLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOME/$targetLinkDirectory" ];  then
          # It is a symlink!
          log_debug "Remove symlink $HOME/$targetLinkDirectory"
          rm "$HOME/$targetLinkDirectory"
          ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
          log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$targetLinkDirectory"
        fi
        ln -s "/data/$sourceLinkDirectory" "$HOME/$targetLinkDirectory"
        log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$targetLinkDirectory"
      fi
    done

    # For Firefox only
    if [[ "$noPrompt" -ne 1 ]]; then
      read -rp "Do you want to link to Data's Firefox (y/n): " qfirefox
      if [[ $qfirefox = [Yy1] ]]; then
        sourceLinkDirectory="$HOME/.mozilla"
        if [ -d "$sourceLinkDirectory" ]; then
          rm -R "$sourceLinkDirectory"
          ln -s /data/.mozilla "$sourceLinkDirectory"
        fi
      fi
    else
      sourceLinkDirectory"$HOME/.mozilla"
      if [ -d "$sourceLinkDirectory" ]; then
        rm -R "$sourceLinkDirectory"
        ln -s /data/.mozilla "$sourceLinkDirectory"
      fi
    fi
  fi
  cd "$currentPath" || exit
  pressEnterToContinue "Data Directories linked to /data."
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                 Physical Machine Setup                                   O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# ownCloud Client Application Install
ownCloudClientInstallApp () {
  log_info "ownCloud Install"
  println_blue "ownCloud Install                                                     "
  wget -q -O - "https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$distReleaseVer/Release.key" | sudo apt-key add -
  echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$distReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$distReleaseVer.list"
  repoUpdate
  sudo apt install -yf owncloud-client
  # sudo apt install -yf
  pressEnterToContinue "ownCloud Client installed."
}

# ############################################################################
# DisplayLink Software install
displayLinkInstallApp () {

  currentPath=$(pwd)
  log_info "display Link Install App"
  println_blue "display Link Install App                                             "
	sudo apt install -y libegl1-mesa-drivers xserver-xorg-video-all xserver-xorg-input-all dkms libwayland-egl1-mesa

  cd "$HOME/tmp" || return
	wget -r -t 10 --output-document=displaylink.zip  http://www.displaylink.com/downloads/file?id=1123
  mkdir -p "$HOME/tmp/displaylink"
  unzip displaylink.zip -d "$HOME/tmp/displaylink/"
  chmod +x "$HOME/tmp/displaylink/displaylink-driver-4.2.run"
  sudo "$HOME/tmp/displaylink/displaylink-driver-4.2.run"

  sudo chown -R "$USER":"$USER" "$HOME/tmp/displaylink/"
  cd "$currentPath" || return
  sudo apt install -yf
  pressEnterToContinue "DisplayLink installed."
}

# ############################################################################
# XPS Display Drivers inatallations
laptopDisplayDrivers () {
  log_info "Install XPS Display Drivers"
  println_blue "Install XPS Display Drivers                                          "
  #get intel key for PPA that gets added during install
  wget --no-check-certificate https://download.01.org/gfx/RPM-GPG-GROUP-KEY-ilg -O - | sudo apt-key add -
  sudo apt install -y nvidia-current intel-graphics-update-tool
  pressEnterToContinue "NVidia and Intel Display drivers installed."
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
    log_warning "Beta Code, downgrade the Gnome3 Backport apt sources."
    # changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" xenial
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  fi
  repoUpdate
	repoUpgrade
  sudo apt install -y gnome gnome-shell
  pressEnterToContinue "Gnome3 Backports and Gnome installed."
}
# ############################################################################
# gnome3Settings
gnome3Settings () {
  log_info "Change Gnome3 settings"
  println_blue "Change Gnome3 settings                                               "
	gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
  pressEnterToContinue "Gnome Settings changed."
}

# ############################################################################
# kdeBetaBackportsRepo
kdeBetaBackportsRepo () {
  log_info "Add KDE Beta Backports Repo"
  println_blue "Add KDE Beta Backports Repo                                               "
  sudo add-apt-repository -y ppa:kubuntu-ppa/beta
  # if [[ $betaAns == 1 ]]; then
  #   log_warning "Beta Code, downgrade the KDE Backport apt sources."
  #   changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  # fi
  pressEnterToContinue "KDE BETA Backports enabled."
}
# ############################################################################
# kdeBackportsApps
kdeBackportsApps () {
  log_info "Add KDE Backports"
  println_blue "Add KDE Backports                                                             "
  sudo add-apt-repository -y ppa:kubuntu-ppa/backports
  sudo add-apt-repository -y ppa:kubuntu-ppa/backports-landing
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, downgrade the KDE Backport apt sources."
    changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "KDE Backports Repos not available as yet, downgrade the apt sources."
    println_red "KDE Backports Repos not available as yet, downgrade the apt sources."
    changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-landing-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    # changeAptSource "/etc/apt/sources.list.d/.list" "$distReleaseName" "$stableReleaseName"
  fi
  repoUpdate
  repoUpgrade
  sudo apt full-upgrade -y;
  pressEnterToContinue "KDE Backports enabled and KDE updated."
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
  sudo add-apt-repository -y ppa:webupd8team/atom
  sudo apt install -y abs-guide atom eclipse idle3 idle3-tools shellcheck eric eric-api-files gitk git-flow giggle gitk gitg maven hunspell hunspell-af hunspell-en-us hunspell-en-za hunspell-en-gb;
  # wget -P "$HOME/tmp" https://release.gitkraken.com/linux/gitkraken-amd64.deb
  # sudo dpkg -i --force-depends "$HOME/tmp/gitkraken-amd64.deb"
  bashdbInstall
  sudo apt install -yf;
  # The following packages was installed in the past but never used or I could not figure out how to use them.
  #
  # sudo snap install --classic --beta atom
  cd "$currentPath" || return
  pressEnterToContinue "Development Applications installed."
}

# ############################################################################
# Git packages installation
gitInstall() {
  currentPath=$(pwd)
  log_info "Git Apps install"
  println_banner_yellow "Git Apps install                                                     "
  sudo apt install -y gitk git-flow giggle gitk gitg
  wget -P "$HOME/tmp" https://release.gitkraken.com/linux/gitkraken-amd64.deb
  sudo dpkg -i --force-depends "$HOME/tmp/gitkraken-amd64.deb"
  sudo apt install -yf
  cd "$currentPath" || return
  pressEnterToContinue "Git Tooling installed."
}

# ############################################################################
# Bashdb packages installation
bashdbInstall() {
  currentPath=$(pwd)
  log_info "Bash Debugger 4.4-0.94 install"
  println_banner_yellow "Bash Debugger 4.4-0.94 install                                       "
  wget https://netix.dl.sourceforge.net/project/bashdb/bashdb/4.4-0.94/bashdb-4.4-0.94.tar.gz
  tar -xvfz bashdb-4.4-0.94.tar.gz
  cd bashdb-4.4-0.94.tar.gz || die "Path bashdb-4.4-0.94.tar.gz does not exist"
  ./configure
  make
  sudo make install

  # install bashdb and ddd
  # printf "Please check ddd-3 version"
  # sudo apt build-dep ddd
  # sudo apt install -y libmotif-dev
  # wget -P "$HOME/tmp http://ftp.gnu.org/gnu/ddd/ddd-3.3.12.tar.gz"
  # wget -P "$HOME/tmp http://ftp.gnu.org/gnu/ddd/ddd-3.3.12.tar.gz.sig"
  # tar xvf "$HOME/tmp/ddd-3.3.9.tar.gz"
  # cd "$HOME/tmp/ddd-3.3.12" || return
  # ./configure
  # make
  # sudo make install
  cd "$currentPath" || return
  pressEnterToContinue "Bashdb installed."
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
  sudo apt install lighttable-installer
  cd "$currentPath" || return
  pressEnterToContinue "LightTable installed."
}

# ############################################################################
# Brackets DevApp installation
bracketsInstall() {
  # Brackets
  println_blue "Brackets"
  log_info "Brackets"
  sudo add-apt-repository -y ppa:webupd8team/brackets
  if [[ $betaAns == 1 ]]; then
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-brackets-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
  sudo apt install brackets
  pressEnterToContinue "Brackets installed."
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
  log_info "UGet Chrome Wrapper"
  println_blue "UGet Chrome Wrapper"
  sudo add-apt-repository -y ppa:slgobinath/uget-chrome-wrapper
  # repoUpdate
  sudo apt-get install google-chrome-stable uget-chrome-wrapper
  pressEnterToContinue "Google Chrome installed."
}

# ############################################################################
# Install Fonts
fontsInstall () {
  log_info "Install Fonts"
  println_blue "Install Fonts"
  sudo apt install -y fonts-inconsolata ttf-staypuft ttf-dejavu-extra fonts-dustin ttf-marvosym fonts-breip fonts-dkg-handwriting ttf-isabella ttf-summersby ttf-sjfonts ttf-mscorefonts-installer ttf-xfree86-nonfree cabextract t1-xfree86-nonfree ttf-dejavu ttf-georgewilliams ttf-bitstream-vera ttf-dejavu ttf-dejavu-extra ttf-aenigma fonts-firacode;
	# sudo apt install -y  ttf-dejavu-udeb ttf-dejavu-mono-udeb ttf-liberation ttf-freefont;
  pressEnterToContinue "Fonts installed."
}

# ############################################################################
# Install inSync for GoogleDrive
insyncInstall () {
  log_info "Install inSync for GoogleDrive"
  println_blue "Install inSync for GoogleDrive"
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
  echo "deb http://apt.insynchq.com/ubuntu $distReleaseName non-free contrib" | sudo tee "/etc/apt/sources.list.d/ownCloudClient-$distReleaseVer.list"
  repoUpdate
  sudo apt-get install insync
  pressEnterToContinue "inSync for GoogleDrive installed."
}

# ############################################################################
# Install Doublecmd
doublecmdInstall () {
  log_info "Install Doublecmd"
  println_blue "Install Doublecmd"
  # wget -nv https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_18.04/Release.key -O "$HOME/tmp/Release.key" | sudo apt-key add -
  if [[ $betaAns != 1 ]]; then
    wget -q "https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_$distReleaseVer/Release.key" -O- | sudo apt-key add -
    echo "deb http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_$distReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/Alexx2000-$distReleaseName.list"
  else
    wget -q "https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_$stableReleaseVer/Release.key" -O- | sudo apt-key add -
    echo "deb http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_$stableReleaseVer/ /" | sudo tee "/etc/apt/sources.list.d/Alexx2000-$stableReleaseName.list"
  fi
  # sudo apt-add-repository -y ppa:alexx2000/doublecmd

  repoUpdate
  sudo apt-get install doublecmd-qt5 doublecmd-help-en doublecmd-plugins
  pressEnterToContinue "Doublecmd installed."
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
  if [[ $betaAns != 1 ]] || [[ $noCurrentReleaseRepo != 1 ]]; then
    log_warning "Add Docker to repository."
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $distReleaseName stable" | sudo tee "/etc/apt/sources.list.d/docker-$distReleaseName.list"
  else
    log_info "Add Docker to repository with stable release $stableReleaseName"
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $stableReleaseName stable" | sudo tee "/etc/apt/sources.list.d/docker-$stableReleaseName.list"
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
  pressEnterToContinue "Docker installed."
}

# #########################################################################
# Install Dropbox Application
dropboxInstall () {
  log_info "Dropbox Install"
  println_blue "Dropbox Install"
  # sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
  # sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ oneiric main" >> /etc/apt/sources.list.d/dropbox.list'
  # sudo sh -c 'echo "#deb http://linux.dropbox.com/ubuntu/ precise main" >> /etc/apt/sources.list.d/dropbox.list'
  # sudo sh -c 'echo "#deb http://linux.dropbox.com/ubuntu/ quantal main" >> /etc/apt/sources.list.d/dropbox.list'
  # sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ trusty main" >> /etc/apt/sources.list.d/dropbox.list'
  # sudo sh -c "echo deb http://linux.dropbox.com/ubuntu/ $stableReleaseName main >> /etc/apt/sources.list.d/dropbox-$stableReleaseName.list"
  # log_warning "Change Dropbox to $ltsReleaseName"
  # println_blue "Change Dropbox to $ltsReleaseName"
  # changeAptSource "/etc/apt/sources.list.d/dropbox-$stableReleaseName.list" "$stableReleaseName" "$ltsReleaseName"
  #sudo apt install -y dropbox
  rm -R "${HOMEDIR/.dropbox-dist/*:?}"
  cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
  if [[ "$noPrompt" -ne 1 ]]; then
    read -rp "Do you want to start the Dropbox initiation and setup? (Y/N)" answer
    if [[ $answer = [Yy1] ]]; then
      ~/.dropbox-dist/dropboxd
    fi
  fi
  pressEnterToContinue "Dropbox installed."
}

# ############################################################################
# Ruby Repository directories to host
rubyRepo () {
  log_info "Ruby Repo"
  println_blue "Ruby Repo"
  sudo apt-add-repository -y ppa:brightbox/ruby-ng
  pressEnterToContinue "Ruby Repo enabled."
}

# ############################################################################
# Vagrant Install, vmtools, nfs directories to host
vagrantInstall () {
  log_info "Vagrant Applications Install"
  println_blue "Vagrant Applications Install                                               "
  rubyRepo
  sudo add-apt-repository ppa:tiagohillebrandt/vagrant

  sudo apt install -yf libvirt-bin libvirt-clients libvirt-daemon dnsutils vagrant vagrant-cachier vagrant-libvirt vagrant-sshfs ruby ruby-dev ruby-dnsruby libghc-zlib-dev ifupdown numad radvd auditd systemtap zfsutils pm-utils;
  vagrant plugin install vbguest vagrant-vbguest vagrant-dns vagrant-registration vagrant-gem vagrant-auto_network vagrant-sshf
  sudo gem install rubydns nio4r pristine hitimes libvirt libvirt-ruby ruby-libvirt rb-fsevent nokogiri vagrant-dns
  pressEnterToContinue "Vagrant installed."
}

# ############################################################################
# AsciiDoc packages installation
asciiDocInstall() {
  currentPath=$(pwd)
  log_info "AsciiDoc Apps install"
  println_banner_yellow "AsciiDoc Apps install                                                     "

  rubyRepo
  repoUpdate
  sudo apt install -y asciidoctor graphviz asciidoc umlet pandoc asciidoctor ruby plantuml;
  sudo gem install bundler guard rake asciidoctor-diagram asciidoctor-plantuml
  cd "$currentPath" || return
  pressEnterToContinue "AsciiDoc Applications installed."
}

# ############################################################################
# Syncwall, WoeUSB packages installation
webupd8AppsInstall() {
  log_info "WebUpd8: SyncWall, ?WoeUSB? Applictions Install"
  println_blue "WebUpd8: SyncWall, WoeUSB Applications Install"
  sudo add-apt-repository -y ppa:nilarimogard/webupd8
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Repos not available as yet, downgrade WebUpd8 apt sources."
    println_red "Repos not available as yet, downgrade WebUpd8 apt sources."
    changeAptSource "/etc/apt/sources.list.d/nilarimogard-ubuntu-webupd8-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  fi
  if [[ "$noPrompt" -ne 1 ]]; then
    read -rp "Do you want to install Syncwall? (Y/N)" answer
    if [[ $answer = [Yy1] ]]; then
      sudo apt install syncwall
    fi
    read -rp "Do you want to install WoeUSB? (Y/N)" answer
    if [[ $answer = [Yy1] ]]; then
      sudo apt install woeusb
    fi
  else
    sudo apt install syncwall woeusb
  fi
}

# ############################################################################
# Y-PPA Manager packages installation
yppaManagerInstall() {
  log_info "Y-PPA Manager Appliction Install"
  println_blue "Y-PPA Manager Application Install"
  sudo add-apt-repository -y ppa:webupd8team/y-ppa-manager
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Distribution, downgrade Y-PPA Manager apt sources."
    println_red "Beta Distribution, downgrade Y-PPA Manager apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
  sudo apt install y-ppa-manager
}

# ############################################################################
# Oracle Java  Installer from WebUpd8 packages installation
oracleJava8Install() {
  log_info "Oracle Java8 Installer from WebUpd8"
  println_blue "Oracle Java8 Installer from WebUpd8"
  sudo add-apt-repository -y ppa:webupd8team/java
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Repos not available as yet, downgrade Oracle Java8 Installer apt sources."
    println_red "Repos not available as yet, downgrade Oracle Java Installer apt sources."
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  fi
  sudo apt install oracle-java8-installer
}


oracleJava10Install() {
  log_info "Oracle Java10 Installer from WebUpd8"
  println_blue "Oracle Java10 Installer from WebUpd8"
  sudo add-apt-repository ppa:linuxuprising/java
  # if [[ $noCurrentReleaseRepo == 1 ]]; then
  #   log_warning "Repos not available as yet, downgrade Oracle Java10 Installer apt sources."
  #   # println_red "Repos not available as yet, downgrade Oracle Java Installer apt sources."
  #   changeAptSource "/etc/apt/sources.list.d/linuxuprising-ubuntu-java-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  # fi
  sudo apt install oracle-java10-installer
  sudo apt install oracle-java10-set-default
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
  sudo apt install grub-customizer
}

# ############################################################################
# Variety packages installation
varietyInstall() {
  log_info "Variety Appliction Install"
  println_blue "Variety Application Install"
  sudo add-apt-repository -y ppa:peterlevi/ppa
  # sudo add-apt-repository -y ppa:variety/daily

  sudo apt install variety variety-slideshow python3-pip
  sudo pip3 install ndg-httpsclient # For variety
}

# ############################################################################
# Boot Repair packages installation
bootRepairInstall() {
  log_info "Boot Repair Appliction Install"
  println_blue "Boot Repair Application Install"
  sudo add-apt-repository -y ppa:yannubuntu/boot-repair

  sudo apt install boot-repair
}

# ############################################################################
# UNetbootin packages installation
unetbootinInstall() {
  log_info "UNetbootin Appliction Install"
  println_blue "UNetbootin Application Install"
  sudo add-apt-repository ppa:gezakovacs/ppa
  sudo apt install unetbootin
}

# ############################################################################
# getdeb repository installation
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
# Latte Dock for KDE packages installation
latteDockInstall() {
  log_info "Latte Dock for KDE Install"
  println_blue "Latte Dock for KDE Install"
  sudo add-apt-repository -y ppa:rikmills/latte-dock
  sudo apt install latte-dock
  kwriteconfig5 --file "$HOME/.config/kwinrc" --group ModifierOnlyShortcuts --key Meta "org.kde.lattedock,/Latte,org.kde.LatteDock,activateLauncherMenu"
  qdbus org.kde.KWin /KWin reconfigure
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
  sudo add-apt-repository -y ppa:inkscape.dev/stable
  if [[ "$distReleaseName" =~ ^($stableReleaseName|$betaReleaseName)$ ]]; then
      log_warning "Change Inkscape to $previousStableReleaseName"
      println_yellow "Change Inkscape to $previousStableReleaseName"
      changeAptSource "/etc/apt/sources.list.d/inkscape_dev-ubuntu-stable-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
  fi
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
  sudo add-apt-repository ppa:philip5/extra
  # sudo apt install -yf
	sudo apt install -yf digikam digikam-doc digikam-data
  # sudo apt install -yf
  pressEnterToContinue "Digikam installed."
}

# #########################################################################
# Install photo applications
photoAppsInstall () {
  currentPath=$(pwd)
  log_info "Photo Apps install"
  println_blue "Photo Apps install                                                   "
  # Darktable
  log_info "Darktable Repo"
  println_blue "Darktable Repo"
  sudo add-apt-repository -y ppa:pmjdebruijn/darktable-release;
  if [[ $betaAns == 1 ]] || [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Beta Code or no new repo, downgrade the apt sources."
    println_red "Beta Code or no new repo, downgrade the apt sources."
    changeAptSource "/etc/apt/sources.list.d/pmjdebruijn-ubuntu-darktable-release-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi

  digikamInstall
  # Rapid Photo downloader
  log_info "Rapid Photo downloader"
  println_blue "Rapid Photo downloader"
  wget -P "$HOME/tmp" https://launchpad.net/rapid/pyqt/0.9.4/+download/install.py
  cd "$HOME/tmp" || return
  python3 install.py

  sudo apt install -y rawtherapee graphicsmagick imagemagick darktable ufraw;

  cd "$currentPath" || return
  pressEnterToContinue "Photography Applications installed."
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

# #########################################################################
# Add all repositories
addRepositories () {
  log_info "Add Repositories"
  println_banner_yellow "Add Repositories                                                     "
    # general repositories
	sudo add-apt-repository -y universe

  pressEnterToContinue "Add Applications Repos enabled."
}

# downgradeAptDistro () {
#   # if [[ $distReleaseName = "xenial" || "yakkety" || "zesty" ]]; then
#   if [[ "$distReleaseName" =~ ^($previousStableReleaseName|$stableReleaseName|$betaReleaseName)$ ]]; then
#     log_info "Change Repos for which there aren't new repos."
#     println_blue "Change Repos for which there aren't new repos."
#     # Commented as it is now a snap install
#     # changeAptSource "/etc/apt/sources.list.d/me-davidsansome-ubuntu-clementine-$distReleaseName.list" "$distReleaseName" $ltsReleaseName
#     case $desktopEnvironment in
#       "kde" )
#         ;;
#       "gnome" )
#         ;;
#       "xubuntu" )
#         ;;
#       "lubuntu" )
#         ;;
#     esac
#   fi
#
#   # older packages that will not install on new releases
#   if ! [[ "$distReleaseName" =~ ^($stableReleaseName|$betaReleaseName)$ ]]; then
#     # Scribes Developer editor
#     # log_warning 'Scribes Developer editor'
#     # sudo add-apt-repository -y ppa:mystilleef/scribes-daily
#     # changeAptSource "/etc/apt/sources.list.d/mystilleef-ubuntu-scribes-daily-$distReleaseName.list" "$distReleaseName" quantal
#     # Canon Printer Drivers
#   	# log_warning "Canon Printer Drivers"
#   	# println_blue "Canon Printer Drivers"
#   	# sudo add-apt-repository -y ppa:michael-gruz/canon-trunk
#   	# sudo add-apt-repository -y ppa:michael-gruz/canon
#   	# sudo add-apt-repository -y ppa:inameiname/stable
#     # changeAptSource "/etc/apt/sources.list.d/michael-gruz-ubuntu-canon-trunk-$distReleaseName.list" "$distReleaseName" utopic
#     # changeAptSource "/etc/apt/sources.list.d/michael-gruz-ubuntu-canon-$distReleaseName.list" "$distReleaseName" quantal
#     # changeAptSource "/etc/apt/sources.list.d/inameiname-ubuntu-stable-$distReleaseName.list" "$distReleaseName" trusty
#     # Inkscape
#   fi
#   if [[ $noCurrentReleaseRepo == 1 ]]; then
#     log_warning "Repos not available as yet, downgrade the apt sources."
#     println_red "Repos not available as yet, downgrade the apt sources."
#     #changeAptSource "/etc/apt/sources.list.d/getdeb-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
#     # changeAptSource "/etc/apt/sources.list.d/.list" "$distReleaseName" "$stableReleaseName"
#   fi
#   pressEnterToContinue "Repos Downgraded."
# }

# ############################################################################
# Install applications
installApps () {
  log_info "Start Applications installation the general apps"
  println_banner_yellow "Start Applications installation the general apps                     "
	# general applications
  sudo apt install -yf
	sudo apt install -yf synaptic gparted aptitude mc filezilla remmina nfs-kernel-server nfs-common samba ssh sshfs rar gawk rdiff-backup luckybackup vim vim-gnome vim-doc tree meld printer-driver-cups-pdf keepassx flashplugin-installer bzr ffmpeg htop iptstate kerneltop vnstat  nmon qpdfview keepnote workrave unison unison-gtk deluge-torrent liferea planner shutter terminator chromium-browser blender caffeine vlc browser-plugin-vlc gufw cockpit autofs openjdk-8-jdk openjdk-8-jre openjdk-11-jdk openjdk-11-jre dnsutils thunderbird network-manager-openconnect network-manager-vpnc network-manager-ssh network-manager-vpnc network-manager-ssh network-manager-pptp openssl xdotool openconnect uget flatpak

  # Older packages...
  # Still active, but replaced with other apps
  # unetbootin = etcher


  # older packages that will not install on new releases
  if ! [[ "$distReleaseName" =~ ^(yakkety|zesty|artful|bionic|cosmic)$ ]]; then
   sudo apt install -yf scribes cnijfilter-common-64 cnijfilter-mx710series-64 scangearmp-common-64 scangearmp-mx710series-64 inkscape
  fi
	# desktop specific applications
	case $desktopEnvironment in
		"kde" )
			sudo apt install -y kubuntu-restricted-addons kubuntu-restricted-extras digikam amarok kdf k4dirstat filelight kde-config-cron kdesdk-dolphin-plugins kcron;
      latteDockInstall
      # Old packages:
      # ufw-kde
			;;
		"gnome" )
			sudo apt install -y gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky nautilus-image-converter wallch alacarte gnome-shell-extensions-gpaste ambiance-colors radiance-colors;
			;;
		"ubuntu" )
			sudo apt install -y gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky nautilus-image-converter wallch alacarte ambiance-colors radiance-colors;
			;;
		"xubuntu" )
			sudo apt install -y gmountiso gnome-commander;
			;;
		"lubuntu" )
			sudo apt install -y gmountiso gnome-commander;
			;;
	esac
  doublecmdInstall
  webupd8AppsInstall
  yppaManagerInstall
  pressEnterToContinue "General Applications installed."
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O           Other Appslications Install                                    O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Install other applications individually
menuOtherApps () {
  ##### Menu section

  until [[ "$choiceApps" =~ ^(0|q|Q|quit)$ ]]; do
    clear
    printf "

    There are the following options for installing individual apps.
    NOTE: The apps will only be installed when you quit this menu so that only one repo update is done.
    TASK : DESCRIPTION
    -----: ---------------------------------------
    1    : VirtualBox Host
    2    : VirtualBox Guest
    3    : Development Apps
    4    : Photography Apps
    6    : Image Editing Applications
    7    : Music and Video Applications
    8    : Oracle Java 9
    10   : Laptop Display Drivers for Intel en Nvidia
    11   : DisplayLink
    12   : ownCloudClient
    13   : Google Chrome browser
    14   : Digikam
    15   : Docker
    16   : Dropbox
    19   : Install extra fonts
    20   : Sunflower
    21   : LibreCAD
    22   : Calibre
    23   : FreeFileSync
    24   : inSync for GoogleDrive
    25   : Doublecmd
    30   : Git
    31   : AsciiDoc
    32   : Vagrant
    33   : Bashdb
    34   : Oracle Java 8
    35   : Oracle Java 10

    0|q  : Quit this program

    "

    read -rp "Enter your choice : " choiceApps
    # printf "%s" "$choiceApps"

    # take inputs and perform as necessary
    case "$choiceApps" in
      1 )
        # VirtualBox Host
        read -rp "Do you want to install VirtualBox Host? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          virtualboxHostInstall
        fi
      ;;
      2 )
        # VirtualBox Guest
        read -rp "Do you want to install VirtualBox Guest? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          repoUpdate
          # sudo apt install -y virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
          virtualboxGuestSetup
        fi
      ;;
      3 )
        # Development Applications
        read -rp "Do you want to install Development Applications? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          devAppsInstall
        fi
      ;;
      4 )
        # Photography Applications
        read -rp "Do you want to install Photography Applications? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          photoAppsInstall
        fi
      ;;
      6 )
        # Imaging Editing Applications
        read -rp "Do you want to install Imaging Editing Applications? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Imaging Editing Applications"
          println_blue "Imaging Editing Applications"
          sudo add-apt-repository -y ppa:otto-kesselgulasch/gimp
          repoUpdate
          sudo apt install -y dia-gnome gimp gimp-plugin-registry gimp-ufraw;
          pressEnterToContinue "Image Editing Applications installed."
        fi
      ;;
      7 )
        # Music and Video apps
        read -rp "Do you want to install Music and Video Apps? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Music and Video apps"
          println_blue "Music and Video apps"
          sudo apt install -y vlc browser-plugin-vlc easytag
          # clementine
          sudo snap install clementine
          pressEnterToContinue "Music and Video Applications installed."
        fi
      ;;
      8)
        # Oracle Java 9
        read -rp "Do you want to install Oracle Java9? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Install Oracle Java9"
          println_blue "Install Oracle Java9"
          echo oracle-java9-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
          sudo apt install -y oracle-java9-installer
          sudo apt-get install oracle-java9-set-default
          pressEnterToContinue "Oracle Java9 installed."
        fi

      ;;
      10 )
        # Freeplane
        read -rp "Do you want to install Freeplane? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Freeplane"
          println_blue "Freeplane"
          sudo apt install -y freeplane
          pressEnterToContinue "Freeplane installed."
        fi
      ;;
      10)
        # Laptop Drivers
        read -rp "Do you want to install Nvidia and Intel Drivers? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          laptopDisplayDrivers
        fi
      ;;
      11)
        # DisplayLink
        read -rp "Do you want to install DisplayLink Drivers? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          displayLinkInstallApp
        fi
      ;;
      12 )
        # ownCloudClient
        read -rp "Do you want to install ownCloudClient? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          ownCloudClientInstall
        fi
      ;;
      13 )
        # Google Chrome
        read -rp "Do you want to install Google Chrome? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          googleChromeInstall
        fi
      ;;
      14 )
        # DigiKam
        read -rp "Do you want to install DigiKam? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          digikamInstall
        fi
      ;;
      15 )
        # Docker
        read -rp "Do you want to install Docker? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          dockerInstall
        fi
      ;;
      16 )
      # Dropbox
        read -rp "Do you want to install Dropbox? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          dropboxInstall
        fi
      ;;
      19 )
        # ExtraFonts
        read -rp "Do you want to install extra Fonts? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          fontsInstall
        fi
      ;;
      20 )
        # Sunflower
        read -rp "Do you want to install Sunflower? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Sunflower"
          println_blue "Sunflower"
          sudo add-apt-repository -y ppa:atareao/sunflower
          log_warning "Change Sunflower to $ltsReleaseName"
          println_blue "Change Sunflower to $ltsReleaseName"
          changeAptSource "/etc/apt/sources.list.d/atareao-ubuntu-sunflower-$distReleaseName.list" "$distReleaseName" "$ltsReleaseName"

          repoUpdate

          sudo apt install -y sunflower
          pressEnterToContinue "Sunflower installed."
        fi
      ;;
      21 )
        # [?] LibreCAD
        read -rp "Do you want to install LibreCAD? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Install LibreCAD"
          println_blue "Install LibreCAD"

          sudo add-apt-repository ppa:librecad-dev/librecad-stable
          changeAptSource "/etc/apt/sources.list.d/librecad-dev-ubuntu-librecad-stable-$distReleaseName.list" "$distReleaseName" $ltsReleaseName

          repoUpdate

          sudo apt install -y librecad
          pressEnterToContinue "Librecad installed."
        fi
      ;;
      22 )
        # Calibre
        read -rp "Do you want to install Calibre? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Calibre"
          println_blue "Calibre"
          sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
          # Use the following f you get certificate issues
          # sudo -v && wget --no-check-certificate -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

          # Github download, above is recommended
          # sudo -v && wget --no-check-certificate -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"
          pressEnterToContinue "Calibre installed."
        fi
      ;;
      23)
        # FreeFileSync
        read -rp "Do you want to install FreeFileSync? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          log_info "Install FreeFileSync"
          println_blue "Install FreeFileSync"
          sudo apt install -y freefilesync
          pressEnterToContinue "FreeFileSync installed."
        fi
      ;;
      24)
        # inSync for GoogleDrive
        read -rp "Do you want to install inSync for GoogleDrive? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          insyncInstall
        fi
      ;;
      25)
        # Doublecmd
        read -rp "Do you want to install Doublecmd? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          doublecmdInstall
        fi
      ;;
      30 )
        # Git
        read -rp "Do you want to install Git? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          gitInstall
        fi
      ;;
      31 )
        # AsciiDoc
        read -rp "Do you want to install AsciiDoc? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          asciiDocInstall
        fi
      ;;
      32 )
        # Vagrant
        read -rp "Do you want to install Vagrant? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          vagrantInstall
        fi
      ;;
      33 )
        read -rp "Do you want to install Bashdb? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          bashdbInstall
        fi
      ;;
      34 )
        read -rp "Do you want to install Oracle Java 8? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          oracleJava8Install
        fi
      ;;
      35 )
        read -rp "Do you want to install Oracle Java 10? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          oracleJava10Install
        fi
      ;;
    	0|q);;
    	*)
        # return 1
    		;;
    esac
  done
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O           Install group apps and other settings                          O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Install settings and applications one by one by selecting options
menuInstallOptions () {
  ##### Menu section
  until [[ $choiceOpt =~ ^(0|q|Q|quit)$ ]]; do
    clear
    printf "

    There are the following options for this script
    TASK : DESCRIPTION
    -----: ---------------------------------------
    1    : Kernel upgrade
    2    : Repositories update
    3    : Repositories upgrade
    4    : Add the additional Repositories for the general applications
    5    : Install the general applications
    6    :
    7    :
    8    : Upgrae KDE to Beta KDE on backports
    10   : Install Gnome Desktop from backports
    11   : Install KDE Desktop from backports
    17   : Setup for a Vmware guest
    18   : Setup for a VirtualBox guest
    19   : Install Development Apps and IDEs
    20   : Setup the home directories to link to the data disk directories
    21   : Create test data directories on data drive

    30   : Set options for an Ubuntu Beta install with PPA references to a previous version

    50   : Change that you don't get any questions
    51   : Change that you get questioned

    0/q  : Quit this program

    "

    read -rp "Enter your choice : " choiceOpt
    # printf "%s" "$choiceOpt"

    # take inputs and perform as necessary
    case "$choiceOpt" in
      1|krnl )
        read -rp "Do you want to do a Kernel update that includes a reboot? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kernelUprade
        fi
      ;;
      2|updt )
        repoUpdate
      ;;
      3|upgr )
        read -rp "Do you want to do a start with an update and upgrade, with a possible reboot? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kernelUprade
        fi
      ;;
      4|addrepos)
        read -rp "Do you want to add the general Repo Keys? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          addRepositories
        fi
        # read -rp "Do you want to downgrade some of the repos that do not have updates for the latest repos? (y/n)" answer
        # if [[ $answer = [Yy1] ]]; then
        #   downgradeAptDistro
        # fi
        read -rp "Do you want to go through adding Repo Keys of the selection above? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          repoUpdate
        fi
      ;;
      5|instapps)
        read -rp "Do you want to do install the applications? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          installApps
        fi
      ;;
      6 )
      ;;
      10 )
        read -rp "Do you want to install Gnome from the Backports? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          gnome3Backports
          read -rp "Do you want to set the Gnome Window buttons to the left? (y/n)" answer
          if [[ $answer = [Yy1] ]]; then
            gnome3Settings
          fi
        fi
      ;;
      7 )
      ;;
      8 )
        read -rp "Do you want to add the KDE Beta Backports apt sources? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kdeBetaBackportsRepo
        fi
      ;;
      11 )
        read -rp "Do you want to install KDE from the Backports? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kdeBackportsApps
        fi
      ;;
      17 )
        read -rp "Do you want to install and setup for VMware guest? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          vmwareGuestSetup
        fi
      ;;
      18 )
        read -rp "Do you want to install and setup for VirtualBox guest? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          virtualboxGuestSetup
        fi
      ;;

      20 )
        read -rp "Do you want to update the home directory links for the data drive? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          dataDirLinksSetup
        fi
      ;;
      21 )
        read -rp "Do you want to create the test home directories on the data drive? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          createTestDataDirs
        fi
      ;;
      19 )
        devAppsInstall
      ;;
      30 )
        println_yellow "Running $desktopEnvironment $distReleaseName $distReleaseVer"
        read -rp "Do you want to setup the build for a beta install? (y/n) " answer
        if [[ $answer = [Yy1] ]]; then
          betaAns=1
          validchoice=0
          until [[ $validchoice == 1 ]]; do
            clear
            printf "



            There are the following options for changing the distribution app sources to a stable release:
            Key  : Stable Release
            -----: ---------------------------------------
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
            case $stablechoice in
              c)
                stableReleaseName="cosmic"
                stableReleaseVer="18.10"
                betaReleaseName="cosmic"
                betaReleaseVer="18.10"
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
      ;;
      50)
        # answer=y
        noPrompt=1
        println_blue "Questions asked OFF\n No questions will be asked"
        log_debug "Questions asked OFF\n No questions will be asked"
      ;;
      51)
        # answer=n
        noPrompt=0
        println_blue "Questions asked ON\n All questions will be asked"
        log_debug "Questions asked ON\n All questions will be asked"
      ;;
    	0|q);;
    	*)
        return 1
    		;;
    esac
  done
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O           Automated Apps Install                                         O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Question run ask questions before run function $1 = l (laptop), w (workstation), vm (vmware virtual machine), vb (virtualbox virtual machine)
questionRun () {
  printf "Question before install asking for each type of install type\n"
  read -rp "Do you want to do a Kernel update? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    kernelUpradeAns=1
  else
    read -rp "Do you want to do a start with an update and upgrade, with a possible reboot? (y/n)" answer
    if [[ $answer = [Yy1] ]]; then
      startUpdateAns=1
    fi
  fi
  case $1 in
    [lw] )
      read -rp "Do you want to update the home directory links for the data drive? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        homeDataDirAns=1
      fi
      read -rp "Do you want to install ownCloudClient? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        ownCloudClientAns=1
      fi
      if [[ $1 = l ]]; then
        read -rp "Do you want to install Intel and Nvidia Display drivers? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          displayDriversAns=1
        fi
        read -rp "Do you want to install DisplayLink? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          displayLinkAns=1
        fi
      fi
    ;;
    vm )
      read -rp "Do you want to install and setup for VMware guest? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        vmwareGuestSetupAns=1
      fi
    ;;
    vb )
      read -rp "Do you want to install and setup for VirtualBox guest? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        virtualBoxGuestSetupAns=1
      fi
    ;;
  esac
  case $desktopEnvironment in
    gnome)
      read -rp "Do you want to install Gnome Backports? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        gnomeBackportsAns=1
      fi
      read -rp "Do you want to set the Gnome Window buttons to the left? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        gnomeButtonsAns=1
      fi
      ;;
    kde)
      read -rp "Do you want to install KDE Backports? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        kdeBackportsAns=1
      fi
      ;;
  esac
  read -rp "Do you want to install Doublecmd? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    doublecmdAns=1
  fi
  read -rp "Do you want to install Google Chrome? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    chromeAns=1
  fi
  read -rp "Do you want to install DigiKam? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    digiKamAns=1
  fi
  read -rp "Do you want to install Docker? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    dockerAns=1
  fi
  read -rp "Do you want to install Dropbox? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    dropboxAns=1
  fi
  read -rp "Do you want to install Photography Apps? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    photoAns=1
  fi
  read -rp "Do you want to install AsciiDoc? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    asciiDocAns=1
  fi
  read -rp "Do you want to install Vagrant? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    vagrantAns=1
  fi
  read -rp "Do you want to install Development Apps? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    devAppsAns=1
    read -rp "Do you want to install Git? (y/n)" answer
    if [[ $answer = [Yy1] ]]; then
      gitAns=1
    fi
  fi
  read -rp "Do you want to install extra Fonts? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    fontsAns=1
  fi
  read -rp "Do you want to add the general Repo Keys? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    addGenRepoAns=1
  fi
  # read -rp "Do you want to downgrade some of the repos that do not have updates for the latest repos? (y/n)" answer
  # if [[ $answer = [Yy1] ]]; then
  #   downgradeAptDistroAns=1
  # fi
  read -rp "Do you want to go through adding Repo Keys of the selection above? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    addRepoAns=1
  fi
  read -rp "Do you want to do a Repo Update? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    repoUpdateAns=1
  fi
  read -rp "Do you want to do a Repo Upgrade? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    repoUpgradeAns=1
  fi
  read -rp "Do you want to do install the applications? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    installAppsAns=1
  fi
  # end of questions
  # debug "You want to stop"
  # printf "######## STOP ##########"
  # read -rp "Do you want to stop? (y/n)" answer
  # if [[ $answer = [Yy1] ]]; then
  #   exit 0;
  # fi

  # start of repositories setup
  if [[ $kernelUpradeAns = 1 ]]; then
    kernelUprade
  fi
  if [[ $startUpdateAns = 1 ]]; then
    repoUpdate
    repoUpgrade
  fi
  if [[ $addRepoAns = 1 ]]; then
    #statements
    if [[ $devAppsAns = 1 ]]; then
      rubyRepo
    fi
    case $desktopEnvironment in
      gnome )
      ;;
      kde )
        if [[ $kdeBackportsAns = 1 ]]; then
          kdeBackportsApps
        fi
      ;;
    esac
    if [[ $addGenRepoAns = 1 ]]; then
      addRepositories
    fi
  fi
  # if [[ $downgradeAptDistroAns = 1 ]]; then
  #   downgradeAptDistro
  # fi

  # update repositories
  if [[ $repoUpdateAns = 1 ]]; then
    repoUpdate
  fi

  #start of application install
  if [[ $installAppsAns = 1 ]]; then
    log_info "Start Applications installation"
    println_banner_yellow "Start Applications installation                                    "
    if [[ $homeDataDirAns = 1 ]]; then
      dataDirLinksSetup
    fi
    if [[ $vmwareGuestSetupAns = 1 ]]; then
      vmwareGuestSetup
    fi
    if [[ $virtualBoxGuestSetupAns = 1 ]]; then
      virtualboxGuestSetup
    fi
    if [[ $displayDriversAns = 1 ]]; then
      laptopDisplayDrivers
    fi
    if [[ $displayLinkAns = 1 ]]; then
      displayLinkInstallApp
    fi
    if [[ $ownCloudClientAns = 1 ]]; then
      ownCloudClientInstall
    fi
    if [[ $doublecmdAns = 1 ]]; then
      doublecmdInstall
    fi
    if [[ $chromeAns = 1 ]]; then
      googleChromeInstall
    fi
    if [[ $digiKamAns = 1 ]]; then
      digikamInstall
    fi
    if [[ $dockerAns = 1 ]]; then
      dockerInstall
    fi
    if [[ $dropboxAns = 1 ]]; then
      dropboxInstall
    fi
    if [[ $desktopEnvironment = "gnome" ]]; then
      if [[ $gnomeBackportsAns = 1 ]]; then
        gnome3Backports
      fi
      if [[ $gnomeButtonsAns = 1 ]]; then
        gnome3Settings
      fi
    fi
    if [[ $photoAns = 1 ]]; then
      photoAppsInstall
    fi
    if [[ $devAppsAns = 1 ]]; then
      devAppsInstall
    fi
    if [[ $gitAns = 1 ]]; then
      gitInstall
    fi
    if [[ $asciiDocAns = 1 ]]; then
      asciiDocInstall
    fi
    if [[ $fontsAns = 1 ]]; then
      fontsInstall
    fi
    if [[ $vagrantAns = 1 ]]; then
      vagrantInstall
    fi
    installApps
  fi

  # update distro
  if [[ $repoUpgradeAns = 1 ]]; then
    repoUpgrade
  fi
}

# ############################################################################
# Question run ask questions before run function $1 = l (laptop), w (workstation), vm (vmware virtual machine), vb (virtualbox virtual machine)
questionStepRun () {
  printf "Question each step before installing\n"
  read -rp "Do you want to do a Kernel update? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    kernelUprade
  fi
  read -rp "Do you want to update the home directory links for the data drive? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    dataDirLinksSetup
  fi
  read -rp "Do you want to add the general Repo Keys? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    addRepositories
  fi
  # read -rp "Do you want to downgrade some of the repos that do not have updates for the latest repos? (y/n)" answer
  # if [[ $answer = [Yy1] ]]; then
  #   downgradeAptDistro
  # fi
  read -rp "Do you want to do a Repo Update? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    repoUpdate
  fi
  read -rp "Do you want to do a Repo Upgrade? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    repoUpgrade
  fi
  read -rp "Do you want to do install the applications? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    installApps
  fi
  read -rp "Do you want to install ownCloudClient? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    ownCloudClientInstall
  fi
  read -rp "Do you want to install Intel and Nvidia Display drivers? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    laptopDisplayDrivers
  fi
  read -rp "Do you want to install DisplayLink? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    displayLinkInstallApp
  fi
  read -rp "Do you want to install and setup for VMware guest? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    vmwareGuestSetup
  fi
  read -rp "Do you want to install and setup for VirtualBox GUEST? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    virtualboxGuestSetup
  fi
  case $desktopEnvironment in
    gnome)
      read -rp "Do you want to install Gnome Backports? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        gnome3Backports
      fi
      read -rp "Do you want to set the Gnome Window buttons to the left? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        gnome3Settings
      fi
      ;;
    kde)
      read -rp "Do you want to install KDE Backports? (y/n)" answer
      if [[ $answer = [Yy1] ]]; then
        kdeBackportsApps
      fi
      ;;
  esac
  read -rp "Do you want to install Doublecmd? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    doublecmdInstall
  fi
  read -rp "Do you want to install Google Chrome? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    googleChromeInstall
  fi
  read -rp "Do you want to install DigiKam? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    digikamInstall
  fi
  read -rp "Do you want to install Docker? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    dockerInstall
  fi
  read -rp "Do you want to install Dropbox? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    dropboxInstall
  fi
  read -rp "Do you want to install Photography Apps? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    photoAppsInstall
  fi
  read -rp "Do you want to install AsciiDoc? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    asciiDocInstall
  fi
  read -rp "Do you want to install and setup for VirtualBox HOST? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    virtualboxHostInstall
  fi
  read -rp "Do you want to install Vagrant? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    vagrantInstall
  fi
  read -rp "Do you want to install Development Apps? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    read -rp "Do you want to install Git? (y/n)" answer
    if [[ $answer = [Yy1] ]]; then
      gitInstall
    fi
    rubyRepo
    devAppsInstall
  fi
  read -rp "Do you want to install extra Fonts? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    fontsInstall
  fi
  read -rp "Do you want to do a Repo Update? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    repoUpdate
  fi
  read -rp "Do you want to do a Repo Upgrade? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    repoUpgrade
  fi
}



# ############################################################################
# Autorun function $1 = l (laptop), w (workstation), vm (vmware virtual machine), vb (virtualbox virtual machine)
autoRun () {
  log_info "Start Auto Applications installation"
  println_banner_yellow "Start Auto Applications installation                                 "
  noPrompt=1
  kernelUprade
  case $1 in
    [lwv] )
      rubyRepo
      ;;
  esac
  addRepositories
  # downgradeAptDistro
  repoUpdate
  case $desktopEnvironment in
    gnome )
      gnome3Backports
      gnome3Settings
    ;;
    kde )
      kdeBackportsApps
      if [[ $1 = [lwv] ]]; then
        digikamInstall
      fi
    ;;
  esac

  repoUpgrade

  doublecmdInstall
  googleChromeInstall

  fontsInstall
  installApps

  case $1 in
    vm )
      vmwareGuestSetup
    ;;
    vb )
      # virtualboxGuestSetup
    ;;
    l )
      dataDirLinksSetup
      # laptopDisplayDrivers
      # displayLinkInstallApp
      ownCloudClientInstall
      dockerInstall
      virtualboxHostInstall
      vagrantInstall
      dropboxInstall
      devAppsInstall
      photoAppsInstall
      gitInstall
      asciiDocInstall
    ;;
    w )
      dataDirLinksSetup
      ownCloudClientInstall
      dockerInstall
      virtualboxHostInstall
      vagrantInstall
      dropboxInstall
      devAppsInstall
      photoAppsInstall
      gitInstall
      asciiDocInstall
    ;;
    v )
      createTestDataDirs
      dataDirLinksSetup
      ownCloudClientInstall
      dockerInstall
      dropboxInstall
      devAppsInstall
      photoAppsInstall
      gitInstall
      asciiDocInstall
    ;;
  esac

  # update distro
  repoUpgrade
  # end of run
  noPrompt=0
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

if [[ ("$betaReleaseName" == "$distReleaseName") || ("$betaReleaseVer" == "$distReleaseVer") ]]; then
  betaAns=1
else
  stableReleaseVer=$distReleaseVer
  stableReleaseName=$distReleaseName
fi
log_warning "desktopEnvironment=$desktopEnvironment"
log_warning "distReleaseVer=$distReleaseVer"
log_warning "distReleaseName=$distReleaseName"
# log_warning "stableReleaseVer=$stableReleaseVer"
# log_warning "stableReleaseName=$stableReleaseName"
# log_warning "ltsReleaseName=$ltsReleaseName"
# log_warning "betaReleaseName=$betaReleaseName"
log_warning "betaAns=$betaAns"

log_info "Start of BuildMan"
log_info "===================================================================="

# println_yellow "desktopEnvironment=$desktopEnvironment"
# println_yellow "distReleaseVer=$distReleaseVer"
# println_yellow "distReleaseName=$distReleaseName"
# println_yellow "stableReleaseVer=$stableReleaseVer"
# println_yellow "stableReleaseName=$stableReleaseName"
# println_yellow "ltsReleaseName=$ltsReleaseName"
# println_yellow "betaReleaseName=$betaReleaseName"
# println_yellow "betaAns=$betaAns"

choiceMain=NULL

until [[ "$choiceMain" =~ ^(0|q|Q|quit)$ ]]; do
  clear
  println_info "\n\n"
  println_info "BuildMan                                                    "
  println_info "====================================================================="



  echo -e "
  MESSAGE : In case of options, one value is displayed as the default value.
  Do erase it to use other value.

  BuildMan v0.1

  This script is documented in README.md file.

  Running $LOG_ERROR_COLOR $distReleaseName $distReleaseVer $desktopEnvironment $LOG_DEFAULT_COLOR

  There are the following options for this script
  TASK :     DESCRIPTION

  1    : Install Laptop with all packages without asking
  2    : Install Laptop with all packages asking for groups of packages

  3    : Install Workstation with all packages without asking
  4    : Install Workstation with all packages asking for groups of packages

  5    : Install VMware VM with all packages without asking
  6    : Install VMware VM with all packages asking for groups of packages

  7    : Install VirtualBox VM with all packages without asking
  8    : Install VirtualBox VM with all packages asking for groups of packages

  9    : Install going through the list step by step

  10   : Install other individual applications
  11   : Install individual repos and items

  0/q  : Quit this program

  "
  printf "Enter your system password if asked...\n\n"

  read -rp "Enter your choice : " choiceMain

  # if [[ $choiceMain == 'q' ]]; then
  # 	exit 0
  # fi


  # take inputs and perform as necessary
  case "$choiceMain" in
    1)
    printf "Automated installation for a Laptop\n"
    autoRun l
    echo "Operation completed successfully."
    ;;
    2)
    printf "Laptop Installation asking items:\n"
    questionRun l
    echo -e "Operation completed successfully.\n"
    ;;
    3)
    printf "Automated installation for a Workstation\n"
    autoRun w
    echo "Operation completed successfully."
    ;;
    4)
    printf "Workstation Installation asking items:\n"
    questionRun w
    echo "Operation completed successfully."
    ;;
    5)
    printf "Automated install for a Vmware virtual machine\n"
    autoRun vm
    echo "Operation completed successfully."
    ;;
    # ############################################################################
    6)
      printf "Vmware install asking questions as to which apps to install for the run"
      questionRun vm
      ;;
      # ############################################################################
    7)
      printf "Automated install for a VirtualBox virtual machine\n"
      autoRun vb
      echo "Operation completed successfully."
    ;;
    # ############################################################################
    8)
      printf "VirtualBox install asking questions as to which apps to install for the run"
      questionRun vb
    ;;
    9)
      questionStepRun
    ;;
    10)
      menuOtherApps
    ;;
    11 )
      echo "Selecting itemized installations"
      menuInstallOptions
    ;;
    99 )
      autoRun v
    ;;
    0|q);;
    # *);;
  esac
done

log_info "Jobs done!"
log_info "End of BuildMan"
log_info "===================================================================="

printf "\n\nJob done!\n"
printf "Thanks for using. :-)\n"
# ############################################################################
# set debugging off
# set -xv
exit;
