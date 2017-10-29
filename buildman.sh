#!/bin/bash

# DateVer 2017/10/23
# Buildman V1.2.7
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

# Ready for Artful
betaReleaseName="bionic"
betaReleaseVer="18.04"
stableReleaseName="artful"
stableReleaseVer="17.10"
previousStableReleaseName="zesty"
noCurrentReleaseRepo=1
# Settings for Zesty
# betaReleaseName="artful"
# betaReleaseVer="17.10"
# stableReleaseName="zesty"
# stableReleaseVer="17.04"
# previousStableReleaseName="yakkety"

ltsReleaseName="xenial"
desktopEnvironment=""
kernelRelease=$(uname -r)
distReleaseVer=$(lsb_release -sr)
distReleaseName=$(lsb_release -sc)
noPrompt=0
debugLogFile="buildmandebug.log"
errorLogFile="buildmanerror.log"

mkdir -p ~/tmp
sudo chown "$USER":"$USER" ~/tmp

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
if [[ $scriptDebugToFile == "on" ]]; then
  if [[ -e $debugLogFile ]]; then
    # >$debugLogFile
    echo -en "\n \033[1;31m##############################################################\n\033[0m
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
else
    declare -r LOG_DEFAULT_COLOR="\033[0m"
    declare -r LOG_ERROR_COLOR="\033[1;31m"
    declare -r LOG_INFO_COLOR="\033[1m"
    declare -r LOG_SUCCESS_COLOR="\033[1;32m"
    declare -r LOG_WARN_COLOR="\033[1;33m"
    declare -r LOG_DEBUG_COLOR="\033[1;34m"
    declare -r BANNER_BLUE="\e[7;44;39m"
    declare -r BANNER_YELLOW="\e[0;103;30m"
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

println() {
  local println_text="$1"
  local println_color="$2"

  # Default level to "info"
  [[ -z ${println_color} ]] && println_color="${LOG_INFO_COLOR}";

  echo -e "${println_color} ${println_text} ${LOG_DEFAULT_COLOR}";
  return 0;
}

println_info()      { println "$@"; }
println_banner_yellow()   { println "$1" "${BANNER_YELLOW}"; }
println_banner_blue()   { println "$1" "${BANNER_BLUE}"; }
println_red()     { println "$1" "${LOG_ERROR_COLOR}"; }
println_yellow()   { println "$1" "${LOG_WARN_COLOR}"; }
println_blue()     { println "$1" "${LOG_DEBUG_COLOR}"; }


# ############################################################################
#--------------------------------------------------------------------------------------------------


# ############################################################################
# Die process to exit because of a failure
die() { echo "$*" >&2; exit 1; }

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
  if [[ "$noPrompt" -ne 1 ]]; then
    read -rp "Press ENTER to continue." nullEntry
    printf "%s" "$nullEntry"
  fi
}

# ############################################################################
# Upgrade the system
# Upgrade the system and distro  - hopefully only need to call once
repoUpgrade () {
  log_info "Repo Upgrade"
  println_banner_yellow "Repo Upgrade                                                         "
  sudo apt upgrade -y;
  sudo apt full-upgrade -y;
  sudo apt dist-upgrade -y;
  sudo apt autoremove -y;
  # sudo apt clean -y
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                         Kernel                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Setup Kernel
kernelUpdate () {
  log_info "Kernel Update"
  println_banner_yellow "Kernel Update                                                        "
  # if [[ "$noPrompt" -ne 1 ]]; then
  #   read -rp "Do you want to go ahead with the kernel and packages update, and possibly will have to reboot (y/n)?" answer
  # else
  #   answer=1
  # fi
  read -rp "Do you want to go ahead with the kernel and packages update, and possibly will have to reboot (y/n)?" answer
  if [[ $answer = [Yy1] ]]; then
    sudo apt update -y;
    if [[ "$noPrompt" -ne 1 ]]; then
      read -rp "Press ENTER to continue." nullEntry
      printf "%s" "$nullEntry"
    fi
    sudo apt install -yf build-essential linux-headers-"$kernelRelease" linux-image-extra-"$kernelRelease" linux-signed-image-"$kernelRelease" linux-image-extra-virtual;
    sudo apt upgrade -y;
    sudo apt full-upgrade -y;
    sudo apt dist-upgrade -y;
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
  mkdir -p ~/hostfiles/home
  mkdir -p ~/hostfiles/data
  LINE1="172.22.8.1:/home/juanb/      $HOME/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="172.22.8.1:/data      $HOME/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  LINE3="172.22.1.1:/home/juanb/      $HOME/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE3|h; \${x;s|$LINE3||;{g;t};a\\" -e "$LINE3" -e "}" /etc/fstab
  LINE4="172.22.1.1:/data      $HOME/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE4|h; \${x;s|$LINE4||;{g;t};a\\" -e "$LINE4" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" ~/hostfiles
  # sudo mount -a
}

# ############################################################################
# VirtualBox Guest Setup, vmtools, nfs directories to host
virtalBoxGuestSetup () {
  log_info "VirtualBox setup NFS file share to hostfiles"
  println_blue "VirtualBox setup NFS file share to hostfiles                         "
  sudo apt install -y nfs-common ssh
  mkdir -p ~/hostfiles/home
  mkdir -p ~/hostfiles/data
  LINE1="192.168.56.1:/home/juanb/      $HOME/hostfiles/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="192.168.56.1:/data      $HOME/hostfiles/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" ~/hostfiles
  # sudo mount -a
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                     Home directory setup                                 O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

# ############################################################################
# Links directories to data disk if exists
setupDataDirLinks () {
  log_info "XPS Data Dir links"
	currentPath=$(pwd)
  cd "$HOME" || exit


  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    if [ -d "$HOME/$sourceDataDirectory" ]; then
      if [ -L "$HOME/$sourceDataDirectory" ]; then
        # It is a symlink!
        log_debug "Remove symlink $HOME/data"
        rm "$HOME/$sourceDataDirectory"
        ln -s "/data" "$HOME/$sourceDataDirectory"
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
    "scripts"
    )

    # DATAHOMEDIRECTORIES=(".local"
    # ".config"
    #
    # )

    log_info "linkDataDirectories ${linkDataDirectories[*]}"

    for sourceLinkDirectory in "${linkDataDirectories[@]}"; do
      log_debug "Link directory = $sourceLinkDirectory"
      # remove after testing
      mkdir -p "/data/$sourceLinkDirectory"
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
        sourceLinkDirectory=~/.mozilla
        if [ -d "$sourceLinkDirectory" ]; then
          rm -R "$sourceLinkDirectory"
          ln -s /data/.mozilla "$sourceLinkDirectory"
        fi
      fi
    else
      sourceLinkDirectory=~/.mozilla
      if [ -d "$sourceLinkDirectory" ]; then
        rm -R "$sourceLinkDirectory"
        ln -s /data/.mozilla "$sourceLinkDirectory"
      fi
    fi
  fi



  cd "$currentPath" || exit
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                 Development Apps                                         O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# ############################################################################
# Development packages repositories
devAppsRepos () {
  # Brackets
  log_info "Brackets Repo"
  println_blue "Brackets Repo"
  sudo add-apt-repository -y ppa:webupd8team/brackets
  # Atom
  log_info "Atom Repo"
  println_blue "Atom Repo"
  sudo add-apt-repository -y ppa:webupd8team/atom
  # LightTable
  log_info "LightTable"
  println_blue "LightTable"
  sudo add-apt-repository -y ppa:dr-akulavich/lighttable
  log_warning "Change Lighttable to $ltsReleaseName"
  println_blue "Change Lighttable to $ltsReleaseName"
  changeAptSource "/etc/apt/sources.list.d/dr-akulavich-ubuntu-lighttable-$distReleaseName.list" "$distReleaseName" "$ltsReleaseName"
  if [[ $betaAns == 1 ]]; then
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-brackets-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"

  fi

}

# ############################################################################
# Development packages installation
devAppsInstall(){
  currentPath=$(pwd)
  log_info "Dev Apps install"
  println_banner_yellow "Dev Apps install                                                     "

	# install bashdb and ddd
	# printf "Please check ddd-3 version"
	# sudo apt build-dep ddd
	# sudo apt install -y libmotif-dev
	# wget -P ~/tmp http://ftp.gnu.org/gnu/ddd/ddd-3.3.12.tar.gz
	# wget -P ~/tmp http://ftp.gnu.org/gnu/ddd/ddd-3.3.12.tar.gz.sig
	# tar xvf ~/tmp/ddd-3.3.9.tar.gz
	# cd ~/tmp/ddd-3.3.12 || return
	# ./configure
	# make
	# sudo make install

  repoUpdate
  sudo apt install -y bashdb abs-guide atom eclipse bashdb ddd idle3 idle3-tools brackets shellcheck eric eric-api-files lighttable-installer gitk git-flow giggle gitk gitg maven;
  wget -P ~/tmp https://release.gitkraken.com/linux/gitkraken-amd64.deb
  sudo dpkg -i --force-depends ~/tmp/gitkraken-amd64.deb
  sudo apt install -yf;
  # The following packages was installed in the past but never used or I could not figure out how to use them.
  #
  # sudo snap install --classic --beta atom


	cd "$currentPath" || return
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                 Physical Machine Setup                                   O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# ############################################################################
# ownCloud Client repository
ownCloudClientRepo () {
  log_info "ownCloud Repo"
  println_blue "ownCloud Repo                                                        "
    sudo sh -c "echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_'$stableReleaseVer'/ /' >> /etc/apt/sources.list.d/owncloud-client-$stableReleaseName.list"
  wget -q -O - "http://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$stableReleaseVer/Release.key" | sudo apt-key add -
}

# ############################################################################
# ownCloud Client Application Install
ownCloudClientInstallApp () {
  log_info "ownCloud Install"
  println_blue "ownCloud Install                                                     "
	sudo apt install -y owncloud-client
  sudo apt install -yf
}

# ############################################################################
# DisplayLink Software install
displayLinkInstallApp () {

  currentPath=$(pwd)
  log_info "display Link Install App"
  println_blue "display Link Install App                                             "
	sudo apt install -y libegl1-mesa-drivers xserver-xorg-video-all xserver-xorg-input-all dkms libwayland-egl1-mesa

  cd ~/tmp || return
	wget -r -t 10 --output-document=displaylink.zip http://www.displaylink.com/downloads/file?id=1057
  mkdir -p ~/tmp/displaylink
  unzip displaylink.zip -d ~/tmp/displaylink/
  chmod +x ~/tmp/displaylink/displaylink-driver-1.3.52.run
  sudo ~/tmp/displaylink/displaylink-driver-1.3.52.run

  sudo chown -R "$USER":"$USER" ~/tmp/displaylink/
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
############################################################################
# Desktop environment check and return desktop environment
desktopEnvironmentCheck () {
  log_info "Desktop environment check"
  # println_banner_yellow "Desktop environment check                                            "
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

# ############################################################################
# gnome3BackportsRepo
gnome3BackportsRepo () {
  log_info "Add Gnome3 Backports Repo apt sources"
  println_blue "Add Gnome3 Backports Repo apt sources                                "
	sudo add-apt-repository -y ppa:gnome3-team/gnome3-staging
	sudo add-apt-repository -y ppa:gnome3-team/gnome3
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, downgrade the Gnome3 Backport apt sources."
    # changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" xenial
    changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"

  fi

}
# ############################################################################
# gnome3BackportsApps
gnome3BackportsApps () {
  log_info "Install Gnome3 Backports Apps"
  println_blue "Install Gnome3 Backports Apps                                        "
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
}


# ############################################################################
# kdeBackportsRepo
kdeBackportsRepo () {
  log_info "Add KDE Backports Repo"
  println_blue "Add KDE Backports Repo                                               "
	sudo add-apt-repository -y ppa:kubuntu-ppa/backports
  sudo add-apt-repository -y ppa:kubuntu-ppa/backports-landing
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, downgrade the KDE Backport apt sources."
    changeAptSource "/etc/apt/sources.list.d/kubuntu-ppa-ubuntu-backports-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
}

# ############################################################################
# kdeBackportsRepo
kdeBackportsApps () {
  repoUpdate
  repoUpgrade
  sudo apt full-upgrade -y;
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                   Apps Install                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# ############################################################################
# Google Chrome Install
googleChromeInstall () {
  log_info "Google Chrome Install"
  println_blue "Google Chrome Install"
  	# sudo apt install -y libgconf2-4 libnss3-1d libxss1; # libnss3-1d is no longer in yakkety
	#wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
	#sudo sh -c 'echo "deb - http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
	#sudo apt install google-chrome-stable
	wget -P ~/tmp https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	sudo dpkg -i --force-depends ~/tmp/google-chrome-stable_current_amd64.deb
  sudo apt install -yf
}

# ############################################################################
# Install Fonts
installFonts () {
  log_info "Install Fonts"
  println_blue "Install Fonts"
	sudo apt install -y fonts-inconsolata ttf-staypuft ttf-dejavu-extra fonts-dustin ttf-marvosym fonts-breip ttf-fifthhorseman-dkg-handwriting ttf-isabella ttf-summersby ttf-liberation ttf-sjfonts ttf-mscorefonts-installer	ttf-xfree86-nonfree cabextract t1-xfree86-nonfree ttf-dejavu ttf-georgewilliams ttf-freefont ttf-bitstream-vera ttf-dejavu ttf-aenigma;
}

# ############################################################################
# Configure DockerRepo
configureDockerRepo () {
  log_info "Configure Docker Repo"
  println_blue "Configure Docker Repo"
	# Setup App repository
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
	# sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	# sudo sh -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-$stableReleaseName main' >> /etc/apt/sources.list.d/docker-$stableReleaseName.list"
  if [[ ! "$noCurrentReleaseRepo" = 1  ]]; then
    if [[ ! "$distReleaseName" =~ ^($betaReleaseName)$ ]]; then
      log_warning "Add Docker to repository."
      sudo sh -c "echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $distReleaseName stable' >> /etc/apt/sources.list.d/docker-$distReleaseName.list"
    else
      log_warning "Add Docker to repository, Previous Stable Release, no beta release available."
      sudo sh -c "echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $stableReleaseName stable' >> /etc/apt/sources.list.d/docker-$stableReleaseName.list"
    fi
  else
    log_warning "Add Docker to repository, Change Docker to Previous Stable Release, no current release available."
    sudo sh -c "echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $previousStableReleaseName stable' >> /etc/apt/sources.list.d/docker-$previousStableReleaseName.list"
  fi
}

# ############################################################################
# Configure DockerInstall
configureDockerInstall () {
  currentPath=$(pwd)
  log_info "Configure Docker Install"
  println_blue "Configure Docker Install"
	# Purge the old repo
	sudo apt purge -y lxc-docker docker-engine docker.io
	# Make sure that apt is pulling from the right repository
	# sudo apt-cache policy docker-engine
	sudo apt-cache policy docker-ce

	# Add the additional kernel packages
	# sudo apt install -y "build-essential linux-headers-$kernelRelease linux-image-extra-$kernelRelease" linux-image-extra-virtual
	sudo apt install -y linux-image-extra-virtual

	# Install Docker
	# sudo apt install -y docker-engine
	sudo apt install -y docker-ce

	# Change the images and containers directory to /data/docker
	# Un comment the following if it is a new install and comment the rm line
	# sudo mv /var/lib/docker /data/docker
  if [ -d "/data" ]; then
  # if /data exists then move docker directory to /data/docker.
    if [[ $(sudo docker ps -q) = 1 ]]; then
      sudo docker ps -q | xargs docker kill
    fi
    # sudo docker ps -q | xargs docker kill
    sudo systemctl stop docker
    # sudo cd /var/lib/docker/devicemapper/mnt
    # sudo umount ./*
    sudo mv /var/lib/docker/ /data/docker/
    # sudo rm -R /var/lib/docker
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
	sudo usermod -aG docker "$USER"
	printf "Logout and login for the user to be added to the group"
	printf "Go to https://docs.docker.com/engine/installation/ubuntulinux/ for DNS and Firewall setup"
  if [[ "$noPrompt" -ne 1 ]]; then
    read -rp "Press ENTER to continue." nullEntry
    printf "%s" "$nullEntry"
  fi

  sudo ufw allow 2375/tcp
  cd "$currentPath" || return
  sudo apt install -yf
}

# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O               Photography Apps                                           O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# #########################################################################
# Install digikam repository
installDigikamRepo () {
  log_info "Digikam Repo"
  println_blue "Digikam Repo"
	sudo add-apt-repository -y ppa:kubuntu-ppa/backports
}
# #########################################################################
# Install digikam Application
installDigikamApp () {
  log_info "Digikam Install"
  println_blue "Digikam Install"
  # sudo apt install -yf
	sudo apt install -yf digikam digikam-doc digikam-data
  # sudo apt install -yf
}
# #########################################################################
# Install photo apps repository
photoAppsRepo () {
  log_info "Photo Apps Repositories"
  println_blue "Photo Apps Repositories                                              "
  installDigikamRepo
  # Darktable
  log_info "Darktable"
  println_blue "Darktable"
  sudo add-apt-repository -y ppa:pmjdebruijn/darktable-release;
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, downgrade the apt sources."
    println_red "Beta Code, downgrade the apt sources."
    changeAptSource "/etc/apt/sources.list.d/pmjdebruijn-ubuntu-darktable-release-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
}
# #########################################################################
# Install photo applications
photoAppsInstall () {
  currentPath=$(pwd)
  log_info "Photo Apps install"
  println_blue "Photo Apps install                                                   "

  installDigikamApp
  # Rapid Photo downloader
  log_info "Rapid Photo downloader"
  println_blue "Rapid Photo downloader"
  wget -P ~/tmp https://launchpad.net/rapid/pyqt/0.9.4/+download/install.py
  cd ~/tmp || return
  python3 install.py

  sudo apt install -y rawtherapee graphicsmagick imagemagick darktable;

  cd "$currentPath" || return
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
  # doublecmd
  log_info "doublecmd"
  println_blue "doublecmd"
	sudo apt-add-repository -y ppa:alexx2000/doublecmd
	# WebUpd8 and SyncWall
	log_info "WebUpd8: SyncWall, ?WoeUSB?"
	println_blue "WebUpd8: SyncWall, WoeUSB"
	sudo add-apt-repository -y ppa:nilarimogard/webupd8
	# Y PPA Manager
	log_info "Y PPA Manager"
	println_blue "Y PPA Manager"
	sudo add-apt-repository -y ppa:webupd8team/y-ppa-manager
	# WebUpd8 Java
	log_info "WebUpd8 Java"
	println_blue "WebUpd8 Java"
	sudo add-apt-repository -y ppa:webupd8team/java
	# GetDeb for Filezilla, PyCharm, Calibre, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync
	log_info "Filezilla, PyCharm, Calibre, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync"
	println_blue "Filezilla, PyCharm, Calibre, Divedemux, Luminance, RemoteBox, UMLet, FreeFileSync"
  sudo sh -c "echo 'deb http://archive.getdeb.net/ubuntu $distReleaseName-getdeb apps' >> /etc/apt/sources.list.d/getdeb-$distReleaseName.list"
	wget -q -O- http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
	# Grub Customizer
	log_info "Grub Customizer"
	println_blue "Grub Customizer"
	sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
	# Clementine
  # Commented as it is now a snap install
	# log_info "Clementine"
	# println_blue "Clementine"
	# sudo add-apt-repository -y ppa:me-davidsansome/clementine
	# Boot-Repair
	log_info "Boot-Repair"
	println_blue "Boot-Repair"
	sudo add-apt-repository -y ppa:yannubuntu/boot-repair
	# Variety
	log_info "Variety"
	println_blue "Variety"
	sudo add-apt-repository -y ppa:peterlevi/ppa
	case $desktopEnvironment in
		"kde" )
      sudo add-apt-repository -y ppa:rikmills/latte-dock
			;;
		"gnome" )
			# [4] Ambiance and Radiance Theme Color pack
			log_info "[4] Ambiance and Radiance Theme Color pack"
			println_blue "[4] Ambiance and Radiance Theme Color pack"
			sudo add-apt-repository -y ppa:ravefinity-project/ppa
			;;
		"ubuntu" )
			# [4] Ambiance and Radiance Theme Color pack
      log_info "[4] Ambiance and Radiance Theme Color pack"
      println_blue "[4] Ambiance and Radiance Theme Color pack"
			sudo add-apt-repository -y ppa:ravefinity-project/ppa
			;;
		"xubuntu" )
			;;
		"lubuntu" )
			;;
	esac

}

  downgradeAptDistro () {
  # if [[ $distReleaseName = "xenial" || "yakkety" || "zesty" ]]; then
  if [[ "$distReleaseName" =~ ^($previousStableReleaseName|$stableReleaseName|$betaReleaseName)$ ]]; then
    log_info "Change Repos for which there aren't new repos."
    println_blue "Change Repos for which there aren't new repos."
    # Commented as it is now a snap install
    # changeAptSource "/etc/apt/sources.list.d/me-davidsansome-ubuntu-clementine-$distReleaseName.list" "$distReleaseName" $ltsReleaseName
    case $desktopEnvironment in
      "kde" )
        ;;
      "gnome" )
        log_info "Change Happy Themes to Xenial"
        println_blue "Change Happy Themes to Xenial"
        ;;
      "xubuntu" )
        ;;
      "lubuntu" )
        ;;
    esac
  fi
  if [[ "$distReleaseName" =~ ^($stableReleaseName|$betaReleaseName)$ ]]; then
    log_warning "Change $stableReleaseName and $betaReleaseName Repos for which there aren't new repos."
    println_blue "Change $stableReleaseName and $betaReleaseName Repos for which there aren't new repos."
    case $desktopEnvironment in
      "kde" )
        ;;
      "gnome" )
        log_warning "Change ravefinity-project to $previousStableReleaseName"
        println_blue "Change ravefinity-project to $previousStableReleaseName"
        changeAptSource "/etc/apt/sources.list.d/ravefinity-project-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        # Should not bet here should be in add gnome3 apt repositorites gnome3BackportsRepo
        # changeAptSource "/etc/apt/sources.list.d/gnome3-team-ubuntu-gnome3-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
        ;;
      "xubuntu" )
        ;;
      "lubuntu" )
        ;;
    esac
  fi

  # older packages that will not install on new releases
  if ! [[ "$distReleaseName" =~ ^($stableReleaseName|$betaReleaseName)$ ]]; then
    # Scribes Developer editor
    # log_warning 'Scribes Developer editor'
    # sudo add-apt-repository -y ppa:mystilleef/scribes-daily
    # changeAptSource "/etc/apt/sources.list.d/mystilleef-ubuntu-scribes-daily-$distReleaseName.list" "$distReleaseName" quantal
    # Canon Printer Drivers
  	# log_warning "Canon Printer Drivers"
  	# println_blue "Canon Printer Drivers"
  	# sudo add-apt-repository -y ppa:michael-gruz/canon-trunk
  	# sudo add-apt-repository -y ppa:michael-gruz/canon
  	# sudo add-apt-repository -y ppa:inameiname/stable
    # changeAptSource "/etc/apt/sources.list.d/michael-gruz-ubuntu-canon-trunk-$distReleaseName.list" "$distReleaseName" utopic
    # changeAptSource "/etc/apt/sources.list.d/michael-gruz-ubuntu-canon-$distReleaseName.list" "$distReleaseName" quantal
    # changeAptSource "/etc/apt/sources.list.d/inameiname-ubuntu-stable-$distReleaseName.list" "$distReleaseName" trusty
    # Inkscape
    log_warning "Inkscape"
    println_blue "Inkscape"
    sudo add-apt-repository -y ppa:inkscape.dev/stable
  fi
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, downgrade the apt sources."
    println_red "Beta Code, downgrade the apt sources."
    changeAptSource "/etc/apt/sources.list.d/alexx2000-ubuntu-doublecmd-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/danielrichter2007-ubuntu-grub-customizer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
  if [[ $noCurrentReleaseRepo == 1 ]]; then
    log_warning "Repos not available as yet, downgrade the apt sources."
    println_red "Repos not available as yet, downgrade the apt sources."
    changeAptSource "/etc/apt/sources.list.d/alexx2000-ubuntu-doublecmd-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/getdeb.list" "$distReleaseName" "$previousStableReleaseName"
    # changeAptSource "/etc/apt/sources.list.d/.list" "$distReleaseName" "$stableReleaseName"
  fi
}

# ############################################################################
# Install applications
installApps () {
  log_info "Start Applications installation the general apps"
  println_banner_yellow "Start Applications installation the general apps                     "
	# general applications
  sudo apt install -yf
	sudo apt install -yf synaptic gparted aptitude mc filezilla remmina nfs-kernel-server nfs-common samba ssh sshfs rar gawk rdiff-backup luckybackup vim vim-gnome vim-doc tree meld printer-driver-cups-pdf keepassx flashplugin-installer bzr ffmpeg htop iptstate kerneltop vnstat unetbootin nmon qpdfview keepnote workrave unison unison-gtk deluge-torrent liferea planner shutter terminator chromium-browser google-chrome-stable y-ppa-manager oracle-java9-installer boot-repair grub-customizer variety blender google-chrome-stable caffeine vlc browser-plugin-vlc gufw cockpit autofs;

  # older packages that will not install on new releases
  if ! [[ "$distReleaseName" =~ ^(yakkety|zesty|artful)$ ]]; then
   sudo apt install -yf scribes cnijfilter-common-64 cnijfilter-mx710series-64 scangearmp-common-64 scangearmp-mx710series-64 inkscape
  fi
	# desktop specific applications
	case $desktopEnvironment in
		"kde" )
			sudo apt install -y kubuntu-restricted-addons kubuntu-restricted-extras doublecmd-qt doublecmd-help-en doublecmd-plugins digikam amarok kdf k4dirstat filelight kde-config-cron latte-dock kdesdk-dolphin-plugins ufw-kde;
			;;
		"gnome" )
			sudo apt install -y doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky nautilus-image-converter wallch alacarte gnome-shell-extensions-gpaste ambiance-colors radiance-colors;
			;;
		"ubuntu" )
			sudo apt install -y doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky nautilus-image-converter wallch alacarte ambiance-colors radiance-colors;
			;;
		"xubuntu" )
			sudo apt install -y doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander;
			;;
		"lubuntu" )
			sudo apt install -y doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander;
			;;
	esac
}

# ############################################################################
# Install other applications individually
installOtherApps () {
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
    5    : Dropbox
    6    : Image Editing Applications
    7    : Music and Video Applications
    20   : Sunflower
    21   : LibreCAD
    22   : Calibre
    23   : FreeFileSync
    30   : Git
    31   : AsciiDoc
    32   : Vagrant
    0|q  : Quit this program

    "

    read -rp "Enter your choice : " choiceApps
    # printf "%s" "$choiceApps"

    # take inputs and perform as necessary
    case "$choiceApps" in
      1 )
        sudo sh -c "echo 'deb http://download.virtualbox.org/virtualbox/debian $stableReleaseName non-free contrib' >> /etc/apt/sources.list.d/virtualbox.org.list"
        wget -q -O - http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc | sudo apt-key add -
        repoUpdate
        # sudo apt install virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso;
        sudo apt install virtualbox-5.1 dkms
        case $desktopEnvironment in
          "kde" )
          # sudo apt install -y virtualbox-qt;
          ;;
        esac
      ;;
      2 )
        repoUpdate
        sudo apt install -y virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
      ;;
      3 )
        devAppsRepos
        devAppsInstall
      ;;
      4 )
        photoAppsRepo
        photoAppsInstall
      ;;
      5 )
        # Dropbox
        log_info "Dropbox"
        println_blue "Dropbox"
        sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
        # sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ oneiric main" >> /etc/apt/sources.list.d/dropbox.list'
        # sudo sh -c 'echo "#deb http://linux.dropbox.com/ubuntu/ precise main" >> /etc/apt/sources.list.d/dropbox.list'
        # sudo sh -c 'echo "#deb http://linux.dropbox.com/ubuntu/ quantal main" >> /etc/apt/sources.list.d/dropbox.list'
        # sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ trusty main" >> /etc/apt/sources.list.d/dropbox.list'
        sudo sh -c "echo deb http://linux.dropbox.com/ubuntu/ $stableReleaseName main >> /etc/apt/sources.list.d/dropbox-$stableReleaseName.list"
        log_warning "Change Dropbox to $ltsReleaseName"
        println_blue "Change Dropbox to $ltsReleaseName"
        changeAptSource "/etc/apt/sources.list.d/dropbox-$stableReleaseName.list" "$stableReleaseName" "$ltsReleaseName"

        repoUpdate

        sudo apt install -y dropbox
      ;;
      6 )
        # Imaging Editing Applications
        log_info "Imaging Editing Applications"
        println_blue "Imaging Editing Applications"
        sudo apt install -y dia-gnome gimp gimp-plugin-registry
      ;;
      7 )
        # Music and Video apps
        log_info "Music and Video apps"
        println_blue "Music and Video apps"
        sudo apt install -y vlc browser-plugin-vlc easytag
        # clementine
        sudo snap install clementine
      ;;
      10 )
        # Freeplane
        log_info "Freeplane"
        println_blue "Freeplane"
        sudo apt install -y freeplane
      ;;
      20 )
        # Sunflower
        log_info "Sunflower"
        println_blue "Sunflower"
        sudo add-apt-repository -y ppa:atareao/sunflower
        log_warning "Change Sunflower to $ltsReleaseName"
        println_blue "Change Sunflower to $ltsReleaseName"
        changeAptSource "/etc/apt/sources.list.d/atareao-ubuntu-sunflower-$distReleaseName.list" "$distReleaseName" "$ltsReleaseName"

        repoUpdate

        sudo apt install -y sunflower
      ;;
      21 )
        # [?] LibreCAD
        sudo add-apt-repository ppa:librecad-dev/librecad-stable
        changeAptSource "/etc/apt/sources.list.d/librecad-dev-ubuntu-librecad-stable-$distReleaseName.list" "$distReleaseName" $ltsReleaseName

        repoUpdate

        sudo apt install -y librecad
      ;;
      22 )
        # Calibre
        log_info "Calibre"
        println_blue "Calibre"
        # sudo apt install calibre
        sudo -v && wget --no-check-certificate -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"
      ;;
      23)
        sudo apt install -y freefilesync
      ;;
      30 )
        sudo apt install -y gitk git-flow giggle gitk gitg
        wget -P ~/tmp https://release.gitkraken.com/linux/gitkraken-amd64.deb
        sudo dpkg -i --force-depends ~/tmp/gitkraken-amd64.deb
        sudo apt install -yf
      ;;
      31 )
        sudo apt install -y asciidoctor graphviz asciidoc umlet pandoc asciidoctor-plantuml ruby
        sudo gem install -y bundler
      ;;
      32 )
        sudo apt install -y vagrant-cachier vagrant-sshfs vagrant vagrant-cachier vagrant-libvirt vagrant-sshfs dig ruby-dns ruby ruby-dev dnsutils
        vagrant plugin install vbguest vagrant-vbguest vagrant-dns vagrant-registration vagrant-gem vagrant-auto_network
        sudo gem install rubydns nio4r pristine hitimes libvirt libvirt-ruby ruby-libvirt rb-fsevent nokogiri vagrant-dns
      ;;
    	0|q);;
    	*)
        # return 1
    		;;
    esac
  done
}

# ############################################################################
# Install settings and applications one by one by selecting options
installOptions () {
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
    6    : Upgrade Gnome to Gnome on backports
    7    : Upgrade KDE to KDE on backports
    8    : Install Gnome Desktop from backports
    9    : Install KDE Desktop from backports
    10   : Install Laptop Display Drivers for Intel en Nvidia
    11   : Install DisplayLink
    12   : Install ownCloudClient
    13   : Install Google Chrome browser
    14   : Install Digikam
    15   : Install Docker
    16   : Install extra fonts
    17   : Setup for a Vmware guest
    18   : Setup for a VirtualBox guest
    19   : Install Development Apps and IDEs
    20   : Setup the home directories to link to the data disk directories

    30   : Set options for an Ubuntu Beta install with PPA references to a previous version

    0/q  : Quit this program

    "

    read -rp "Enter your choice : " choiceOpt
    # printf "%s" "$choiceOpt"

    # take inputs and perform as necessary
    case "$choiceOpt" in
      1|krnl )
        read -rp "Do you want to do a Kernel update that includes a reboot? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kernelUpdate
        fi
      ;;
      2|updt )
        repoUpdate
      ;;
      3|upgr )
        read -rp "Do you want to do a start with an update and upgrade, with a possible reboot? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kernelUpdate
        fi
      ;;
      4|addrepos)
        read -rp "Do you want to add the general Repo Keys? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          addRepositories
        fi
        read -rp "Do you want to downgrade some of the repos that do not have updates for the latest repos? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          downgradeAptDistro
        fi
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
        read -rp "Do you want to add the Gnome3 Backports PPA? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          gnome3BackportsRepo
          # repoUpgrade
        fi
        read -rp "Do you want to set the Gnome Window buttons to the left? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          gnome3Settings
        fi
      ;;
      8 )
        read -rp "Do you want to install Gnome from the Backports? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          # gnome3BackportsRepo
          gnome3BackportsApps
        fi
        read -rp "Do you want to set the Gnome Window buttons to the left? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          gnome3Settings
        fi
      ;;
      7 )
        read -rp "Do you want to add the KDE Backports apt sources? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kdeBackportsRepo
        fi
      ;;
      9 )
        read -rp "Do you want to install KDE from the Backports? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          # kdeBackportsRepo
          kdeBackportsApps
        fi
      ;;
      10)
        laptopDisplayDrivers
    		echo "Installed Laptop Display Drivers."
    		;;
    	11)
        displayLinkInstallApp
    	;;
      12 )
        read -rp "Do you want to install ownCloudClient? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          ownCloudClientRepo
          repoUpdate
          ownCloudClientInstallApp
        fi
      ;;
      13 )
        read -rp "Do you want to install Google Chrome? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          googleChromeInstall
        fi
      ;;
      14 )
        read -rp "Do you want to install DigiKam? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          installDigikamRepo
          repoUpdate
          installDigikamApp
        fi
      ;;
      15 )
        read -rp "Do you want to install Docker? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          configureDockerRepo
          repoUpdate
          configureDockerInstall
        fi
      ;;
      16 )
        read -rp "Do you want to install extra Fonts? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          installFonts
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
          virtalBoxGuestSetup
      fi
      ;;

      20 )
        read -rp "Do you want to update the home directory links for the data drive? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          setupDataDirLinks
        fi
      ;;
      19 )
        devAppsRepos
        repoUpdate
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
              b)
                stableReleaseName="bionic"
                stableReleaseVer="18.04"
                betaReleaseName="c"
                betaReleaseVer="18.10"
                previousStableReleaseName="zesty"
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
    	0|q);;
    	*)
        return 1
    		;;
    esac
  done
}

# ############################################################################
# Question run ask questions before run function $1 = l (laptop), w (workstation), vm (vmware virtual machine), vb (virtualbox virtual machine)
questionRun () {
  printf "Question before install asking for each type of install type\n"
  read -rp "Do you want to do a Kernel update? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    kernelUpdateAns=1
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
  read -rp "Do you want to install extra Fonts? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    fontsAns=1
  fi
  read -rp "Do you want to add the general Repo Keys? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    addGenRepoAns=1
  fi
  read -rp "Do you want to downgrade some of the repos that do not have updates for the latest repos? (y/n)" answer
  if [[ $answer = [Yy1] ]]; then
    downgradeAptDistroAns=1
  fi
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

  if [[ $kernelUpdateAns = 1 || $startUpdateAns = 1 ]]; then
    kernelUpdate
  fi
  # start of repositories setup
  if [[ $addRepoAns = 1 ]]; then
    #statements
    if [[ $ownCloudClientAns = 1 ]]; then
      ownCloudClientRepo
    fi
    if [[ $dockerAns = 1 ]]; then
      configureDockerRepo
    fi
    case $desktopEnvironment in
      gnome )
      if [[ $gnomeBackportsAns = 1 ]]; then
        gnome3BackportsRepo
      fi
      if [[ $digiKamAns = 1 ]]; then
        kdeBackportsRepo
      fi
      ;;
      kde )
      if [[ $kdeBackportsAns = 1 ]]; then
        kdeBackportsRepo
      fi
      ;;
    esac
    if [[ $addGenRepoAns = 1 ]]; then
      addRepositories
    fi
  fi
  if [[ $downgradeAptDistroAns = 1 ]]; then
    downgradeAptDistro
  fi

  # update repositories
  if [[ $repoUpdateAns = 1 ]]; then
    repoUpdate
  fi

  #start of application install
  if [[ $installAppsAns = 1 ]]; then
    log_info "Start Applications installation"
    println_banner_yellow "Start Applications installation                                    "
    if [[ $vmwareGuestSetupAns = 1 ]]; then
      vmwareGuestSetup
    fi
    if [[ $virtualBoxGuestSetupAns = 1 ]]; then
      virtalBoxGuestSetup
    fi
    if [[ $displayDriversAns = 1 ]]; then
      laptopDisplayDrivers
    fi
    if [[ $displayLinkAns = 1 ]]; then
      displayLinkInstallApp
    fi
    if [[ $ownCloudClientAns = 1 ]]; then
      ownCloudClientInstallApp
    fi
    if [[ $chromeAns = 1 ]]; then
      googleChromeInstall
    fi
    if [[ $digiKamAns = 1 ]]; then
      installDigikamApp
    fi
    if [[ $dockerAns = 1 ]]; then
      configureDockerInstall
    fi
    if [[ $desktopEnvironment = "gnome" ]]; then
      if [[ $gnomeBackportsAns = 1 ]]; then
        gnome3BackportsApps
      fi
      if [[ $gnomeButtonsAns = 1 ]]; then
        gnome3Settings
      fi
    fi
    if [[ $fontsAns = 1 ]]; then
      installFonts
    fi
    installApps
    if [[ $homeDataDirAns = 1 ]]; then
      setupDataDirLinks
    fi
  fi

  # update distro
  if [[ $repoUpgradeAns = 1 ]]; then
    repoUpgrade
  fi
}


# ############################################################################
# Autorun function $1 = l (laptop), w (workstation), vm (vmware virtual machine), vb (virtualbox virtual machine)
autoRun () {
  log_info "Start Auto Applications installation"
  println_banner_yellow "Start Auto Applications installation                                 "
  noPrompt=1
  kernelUpdate
  case $1 in
    [lw] )
      ownCloudClientRepo
      configureDockerRepo
      ;;
  esac
  case $desktopEnvironment in
    gnome )
      gnome3BackportsRepo
    ;;
    kde )
      kdeBackportsRepo
    ;;
  esac
  addRepositories
  downgradeAptDistro
  repoUpdate
  case $desktopEnvironment in
    gnome )
      gnome3BackportsApps
      gnome3Settings
    ;;
    kde )
    if [[ $1 = [lw] ]]; then
      installDigikamApp
    fi
    ;;
  esac

  googleChromeInstall

  installFonts
  installApps

  case $1 in
    vm )
      vmwareGuestSetup
    ;;
    vb )
      virtalBoxGuestSetup
    ;;
    laptop )
      laptopDisplayDrivers
      displayLinkInstallApp
      ownCloudClientInstallApp
      configureDockerInstall
      setupDataDirLinks
    ;;
    pc )
      ownCloudClientInstallApp
      configureDockerInstall
      setupDataDirLinks
    ;;
  esac

  # update distro
  repoUpgrade
  # end of run
}

# ############################################################################
# Here is where the main script starts
# Above were the functions to be used
choiceMain=NULL

until [[ "$choiceMain" =~ ^(0|q|Q|quit)$ ]]; do

  log_info "Start of BuildMan"
  log_info "===================================================================="
  clear
  println_banner_yellow "Start of BuildMan                                                    "
  println_banner_yellow "====================================================================="

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
  log_warning "stableReleaseVer=$stableReleaseVer"
  log_warning "stableReleaseName=$stableReleaseName"
  log_warning "ltsReleaseName=$ltsReleaseName"
  log_warning "betaReleaseName=$betaReleaseName"
  log_warning "betaAns=$betaAns"

  # println_yellow "desktopEnvironment=$desktopEnvironment"
  # println_yellow "distReleaseVer=$distReleaseVer"
  # println_yellow "distReleaseName=$distReleaseName"
  # println_yellow "stableReleaseVer=$stableReleaseVer"
  # println_yellow "stableReleaseName=$stableReleaseName"
  # println_yellow "ltsReleaseName=$ltsReleaseName"
  # println_yellow "betaReleaseName=$betaReleaseName"
  # println_yellow "betaAns=$betaAns"


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
    10)
    installOtherApps
    ;;
    11)
    echo "Selecting itemized installations"
    installOptions
    ;;
    0|q);;
    *);;
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
