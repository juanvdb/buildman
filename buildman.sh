#!/bin/bash

# UbuntuBuild V1.2.7
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
betaReleaseName="artful"
betaReleaseVer="17.10"
stableReleaseName="zesty"
stableReleaseVer="17.04"
previousStableReleaseName="yakkety"
desktopEnvironment=""
kernelRelease=$(uname -r)
distReleaseVer=$(lsb_release -sr)
distReleaseName=$(lsb_release -sc)
noPrompt=0

mkdir -p ~/tmp
sudo chown "$USER":"$USER" ~/tmp

# Create progress bar and colours for apt
# echo 'Dpkg::Progress-Fancy "1";' | sudo tee -a /etc/apt/apt.conf.d/99progressbar > /dev/null
# cat /dev/null > 99progressbar
# cat << 'EOF' >>  99progressbar
# Dpkg::Progress-Fancy "1";
# APT::Color "1";
#   Dpkg::Progress-Fancy::Progress-Bg "%1b[40m";
# EOF
# sudo mv ./99progressbar /etc/apt/apt.conf.d/99progressbar

#--------------------------------------------------------------------------------------------------
# ############################################################################
# ==> set debugging on
# echo "Press CTRL+C to proceed."
# trap "pkill -f 'sleep 1h'" INT
# trap "set +xv ; sleep 1h ; set -xv" DEBUG
# set -e  # Fail on first error


# source /home/juan/ownCloud/bashscripts/log4bash-master/log4bash.sh
# source /home/juan/data/ownCloud/bashscripts/log4bash-master/log4bash.sh

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
INTERACTIVE_MODE="on"
scriptDebugToStdout="off"
logToFile="on"
if [[ $logToFile == "on" ]]; then
  # cat /dev/null > buildman.log
  # cat /dev/null > buildman_error.log
  if [[ ! -e buildman.log ]]; then
    touch buildman.log
  fi
  if [[ ! -e buildman_error.log ]]; then
    touch buildman_error.log
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
  if [[ $logToFile == "on" ]]
  then
    printf "DEBUG: %q\n" "$@" >>buildman.log 2>>buildman_error.log
  fi
  # [[ $script_debug = 1 ]] && printf "DEBUG: %q\n" "$@" >>buildman.log 2>>buildman_error.log || :
  #log "$@" >>buildman.log 2>>buildman_error.log
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
    declare -r LOG_DEBUG_COLOR=""
else
    declare -r LOG_DEFAULT_COLOR="\033[0m"
    declare -r LOG_ERROR_COLOR="\033[1;31m"
    declare -r LOG_INFO_COLOR="\033[1m"
    declare -r LOG_SUCCESS_COLOR="\033[1;32m"
    declare -r LOG_WARN_COLOR="\033[1;33m"
    declare -r LOG_DEBUG_COLOR="\033[1;34m"
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
    if [[ $logToFile == "on" ]]
    then
      echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}" >>buildman.log 2>>buildman_error.log
    fi
    # [[ $script_debug = 1 ]] && echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}" >>buildman.log 2>>buildman_buildman_error.log || :
    return 0;
}

log_info()      { log "$@"; }
log_success()   { log "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
log_error()     { log "$1" "ERROR" "${LOG_ERROR_COLOR}"; }
log_warning()   { log "$1" "WARNING" "${LOG_WARN_COLOR}"; }
log_debug()     { log "$1" "DEBUG" "${LOG_DEBUG_COLOR}"; }

printline() {
    local log_text="$1"
    local log_level="$2"
    local log_color="$3"

    # Default level to "info"
    [[ -z ${log_level} ]] && log_level="INFO";
    [[ -z ${log_color} ]] && log_color="${LOG_INFO_COLOR}";

    echo -e "${log_color} ${log_text} ${LOG_DEFAULT_COLOR}";
    return 0;
}

printline_info()      { printline "$@"; }
printline_success()   { printline "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
printline_error()     { printline "$1" "ERROR" "${LOG_ERROR_COLOR}"; }
printline_warning()   { printline "$1" "WARNING" "${LOG_WARN_COLOR}"; }
printline_debug()     { printline "$1" "DEBUG" "${LOG_DEBUG_COLOR}"; }

# ############################################################################
#--------------------------------------------------------------------------------------------------


# ############################################################################
# Die process to exit because of a failure
die() { echo "$*" >&2; exit 1; }


# ############################################################################
# Update the repositories
# Update repositories - hopefully only need to call once
repoUpdate () {
  log_info "Repo Update"
  sudo apt -y update;
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
  sudo apt -y upgrade;
  sudo apt -y full-upgrade
  sudo apt -y dist-upgrade;
  sudo apt -y autoremove
  # sudo apt clean
}

# ############################################################################
# Setup Kernel
kernelUpdate () {
  log_info "Kernel Update"
  # if [[ "$noPrompt" -ne 1 ]]; then
  #   read -rp "Do you want to go ahead with the kernel and packages update, and possibly will have to reboot (y/n)?" answer
  # else
  #   answer=1
  # fi
  read -rp "Do you want to go ahead with the kernel and packages update, and possibly will have to reboot (y/n)?" answer
  if [[ $answer = [Yy1] ]]; then
    sudo apt -y update
    if [[ "$noPrompt" -ne 1 ]]; then
      read -rp "Press ENTER to continue." nullEntry
      printf "%s" "$nullEntry"
    fi
    sudo apt -yf install build-essential linux-headers-"$kernelRelease" linux-image-extra-"$kernelRelease" linux-signed-image-"$kernelRelease" linux-image-extra-virtual;
    sudo apt -y upgrade;
    sudo apt -y full-upgrade;
    sudo apt -y dist-upgrade;
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

# ############################################################################
# VMware Guest Setup, vmtools, nfs directories to host
vmwareGuestSetup () {
  log_info "VMware setup with Open VM Tools and NFS file share to host"
  sudo apt install -y nfs-common ssh open-vm-tools open-vm-tools-desktop
  mkdir -p ~/vmhost/home
  mkdir -p ~/vmhost/data
  LINE1="172.22.8.1:/home/juan/      $HOME/vmhost/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="172.22.8.1:/data      $HOME/vmhost/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  LINE3="172.22.1.1:/home/juan/      $HOME/vmhost/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE3|h; \${x;s|$LINE3||;{g;t};a\\" -e "$LINE3" -e "}" /etc/fstab
  LINE4="172.22.1.1:/data      $HOME/vmhost/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE4|h; \${x;s|$LINE4||;{g;t};a\\" -e "$LINE4" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" ~/hostfiles
  # sudo mount -a
}

# ############################################################################
# VirtualBox Guest Setup, vmtools, nfs directories to host
virtalBoxGuestSetup () {
  log_info "VirtualBox setup NFS file share to hostfiles"
  sudo apt install -y nfs-common ssh
  mkdir -p ~/vbhost/home
  mkdir -p ~/vbhost/data
  LINE1="192.168.56.1:/home/juan/      $HOME/vbhost/home    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE1|h; \${x;s|$LINE1||;{g;t};a\\" -e "$LINE1" -e "}" /etc/fstab
  LINE2="192.168.56.1:/data      $HOME/vbhost/data    nfs     rw,intr    0       0"
  sudo sed -i -e "\|$LINE2|h; \${x;s|$LINE2||;{g;t};a\\" -e "$LINE2" -e "}" /etc/fstab
  sudo chown -R "$USER":"$USER" ~/vbhost
  # sudo mount -a
}

# ############################################################################
# Links directories to data disk if exists
setupDataDirLinks () {
  log_info "XPS Data Dir links"
	currentPath=$(pwd)
  cd "$HOME" || exit

  linkDataDirectories=(
  "bin"
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
  "vagrant"
  ".vagrant.d"
  )

    # DATAHOMEDIRECTORIES=(".local"
    # ".config"
    #
    # )

  log_info "linkDataDirectories ${linkDataDirectories[*]}"

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

    for sourceLinkDirectory in "${linkDataDirectories[@]}"; do
      log_debug "Link directory = $sourceLinkDirectory"
      if [ -e "$HOME/$sourceLinkDirectory" ]; then
        if [ -d "$HOME/$sourceLinkDirectory" ]; then
            if [ -L "$HOME/$sourceLinkDirectory" ]; then
              # It is a symlink!
              log_debug "Remove symlink $HOME/$sourceLinkDirectory"
              rm "$HOME/$sourceLinkDirectory"
              ln -s "/data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
              log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
            else
              # It's a directory!
              log_debug "Remove directory $HOME/data"
              rmdir "$HOME/$sourceLinkDirectory"
              ln -s "/data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
              log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
            fi
          else
            rm "$HOME/$sourceLinkDirectory"
            ln -s "/data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
            log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
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
          ln -s "/data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
          log_debug "Create symlink directory ln -s /data/$sourceLinkDirectory $HOME/$sourceLinkDirectory"
        fi
      done
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

# ############################################################################
# Development packages repositories
#devAppsRepos () {}
# ############################################################################
# Development packages installation
devAppsInstall(){
  currentPath=$(pwd)
  log_info "Dev Apps install"

	# install bashdb and ddd
	printline_error "Please check ddd-3 version"
	sudo apt -y install bashdb
	sudo apt -y build-dep ddd
	sudo apt -y install libmotif-dev
	wget -P ~/tmp http://ftp.gnu.org/gnu/ddd/ddd-3.3.12.tar.gz
	wget -P ~/tmp http://ftp.gnu.org/gnu/ddd/ddd-3.3.12.tar.gz.sig
	tar xvf ~/tmp/ddd-3.3.9.tar.gz
	cd ~/tmp/ddd-3.3.12 || return
	./configure
	make
	sudo make install



	cd "$currentPath" || return
}

# ############################################################################
# ownCloud Client repository
ownCloudClientRepo () {
  log_info "ownCloud Repo"
  sudo sh -c "echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_'$stableReleaseVer'/ /' >> /etc/apt/sources.list.d/owncloud-client-$stableReleaseName.list"
  wget -q -O - "http://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$stableReleaseVer/Release.key" | sudo apt-key add -
}

# ############################################################################
# ownCloud Client Application Install
ownCloudClientInstallApp () {
  log_info "ownCloud Install"
	sudo apt -y install owncloud-client
  sudo apt install -yf
}

# ############################################################################
# DisplayLink Software install
displayLinkInstallApp () {

  currentPath=$(pwd)
  log_info "display Link Install App"
	sudo apt -y install libegl1-mesa-drivers xserver-xorg-video-all xserver-xorg-input-all dkms libwayland-egl1-mesa

  cd ~/tmp || return
	wget -r -t 10 --output-document=displaylink.zip http://www.displaylink.com/downloads/file?id=744
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
  #get intel key for PPA that gets added during install
  wget --no-check-certificate https://download.01.org/gfx/RPM-GPG-GROUP-KEY-ilg -O - | sudo apt-key add -
  sudo apt install nvidia-current intel-graphics-update-tool
}

# ############################################################################
# gnome3BackportsRepo
gnome3BackportsRepo () {
  log_info "Add Gnome3 Backports Repo apt sources"
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
	repoUpdate
	repoUpgrade
  sudo apt install -y gnome gnome-shell
}

# ############################################################################
# gnome3Settings
gnome3Settings () {
  log_info "Change Gnome3 settings"
	gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
}


# ############################################################################
# kdeBackportsRepo
kdeBackportsRepo () {
  log_info "Add KDE Backports Repo"
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
  sudo apt -y full-upgradegnm
}

# ############################################################################
# Google Chrome Install
googleChromeInstall () {
  log_info "Google Chrome Install"
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
	sudo apt -y install fonts-inconsolata ttf-staypuft ttf-dejavu-extra fonts-dustin ttf-marvosym fonts-breip ttf-fifthhorseman-dkg-handwriting ttf-isabella ttf-summersby ttf-liberation ttf-sjfonts ttf-mscorefonts-installer	ttf-xfree86-nonfree cabextract t1-xfree86-nonfree ttf-dejavu ttf-georgewilliams ttf-freefont ttf-bitstream-vera ttf-dejavu ttf-aenigma;
}

#
############################################################################
# Desktop environment check and return desktop environment
desktopEnvironmentCheck () {
  log_in "Desktop environment check"
	# another way from stackexchange
	if [[ "$XDG_CURRENT_DESKTOP" = "" ]];
	then
    # shellcheck disable=SC2001
	  desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|plasma\|gnome\).*/\1/')
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
    "ubuntu" ) ;;
    * )
      desktopEnvironment="ubuntu"
      ;;
  esac
}

# #########################################################################
# Install digikam repository
installDigikamRepo () {
  log_info "Digikam Repo"
	sudo add-apt-repository -y ppa:kubuntu-ppa/backports
}
# #########################################################################
# Install digikam Application
installDigikamApp () {
  log_info "Digikam Install"
  # sudo apt install -yf
	sudo apt -yf install digikam digikam-doc digikam-data
  # sudo apt install -yf
}

# ############################################################################
# Configure DockerRepo
# $$$ No longer needed, install with snap
configureDockerRepo () {
  log_info "Configure Docker Repo"
	# Setup App repository
	sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	sudo sh -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-$stableReleaseName main' >> /etc/apt/sources.list.d/docker-$stableReleaseName.list"
  if [[ "$distReleaseName" =~ ^($betaReleaseName)$ ]]; then
    log_warning "Change Docker to Stable Release"
    sudo mv "/etc/apt/sources.list.d/docker-$stableReleaseName.list" "/etc/apt/sources.list.d/docker-ubuntu-$stableReleaseName.list"
    changeAptSource "/etc/apt/sources.list.d/docker-ubuntu-$stableReleaseName.list" "ubuntu-$stableReleaseName" ubuntu-yakkety
  fi
}

# ############################################################################
# Configure DockerInstall
configureDockerInstall () {
  currentPath=$(pwd)
  log_info "Configure Docker Install"
	# Purge the old repo
	# sudo apt -y purge lxc-docker
	# Make sure that apt is pulling from the right repository
	# sudo apt-cache policy docker-engine

	# Add the additional kernel packages
	# sudo apt -y install "build-essential linux-headers-$kernelRelease linux-image-extra-$kernelRelease" linux-image-extra-virtual
	sudo apt -y install linux-image-extra-virtual

	# Install Docker
	# sudo apt -y install docker-engine
  sudo snap install docker

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

	# Create docker group and add $USER
	sudo usermod -aG docker "$USER"
	printline_error "Logout and login for the user to be added to the group\n"
	printline_error "Go to https://docs.docker.com/engine/installation/ubuntulinux/ for DNS and Firewall setup\n"
  if [[ "$noPrompt" -ne 1 ]]; then
    read -rp "Press ENTER to continue." nullEntry
    printline_debug "%s" "$nullEntry"
  fi

  sudo ufw allow 2375/tcp
  cd "$currentPath" || return
  sudo apt install -yf
}

# #########################################################################
# changeAptSource
changeAptSource () {

  infile=$1			#File name of current apt
  oldrelease=$2		#distro release of current apt - typically in the filename, precise, natty, ...
  newrelease=$3		#distro of new release

  log_info "Change Apt Source $infile from $oldrelease to $newrelease"
  # log_debug "Infile=$infile"
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
  # general repositories
	sudo add-apt-repository -y universe
  # doublecmd
  log_debug 'doublecmd'
	sudo apt-add-repository -y ppa:alexx2000/doublecmd
	# Google Chromium
	log_debug "Google Chromium"
	# sudo add-apt-repository -y ppa:chromium-daily/ppa;
	sudo add-apt-repository -y ppa:chromium-daily/stable;
	#Google Chrome
	#log_info 'Google Chrome'
	#wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
	#sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
	# Rapid Photo downloader
	log_debug 'Rapid Photo downloader'
	sudo add-apt-repository -y ppa:dlynch3;
	# VLC Media Player
	# log_debug 'VLC Media Player'
	# sudo add-apt-repository -y ppa:n-muench/vlc
	# Darktable
	log_debug 'Darktable'
	sudo add-apt-repository -y ppa:pmjdebruijn/darktable-release;
	# WebUpd8 and SyncWall
	log_debug 'WebUpd8 and SyncWall'
	sudo add-apt-repository -y ppa:nilarimogard/webupd8
	# Y PPA Manager
	log_debug 'Y PPA Manager'
	sudo add-apt-repository -y ppa:webupd8team/y-ppa-manager
	# WebUpd8 Java
	log_debug 'WebUpd8 Java'
	sudo add-apt-repository -y ppa:webupd8team/java
	# Filezilla
	log_debug 'Filezilla'
	sudo add-apt-repository -y ppa:n-muench/programs-ppa
	# Uncomplicated Firewall frontend
	log_debug 'Uncomplicated Firewall frontend'
	sudo add-apt-repository -y ppa:baudm/ppa;
	# Grub Customizer
	log_debug 'Grub Customizer'
	sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
	# Clementine
	log_debug 'Clementine'
	sudo add-apt-repository -y ppa:me-davidsansome/clementine
	# [?] LibreCAD
	log_debug '[?] LibreCAD'
	sudo add-apt-repository -y ppa:librecad-dev/librecad-stable
	# [?] WinUSB
	log_debug '[?] WinUSB'
	sudo add-apt-repository -y ppa:colingille/freshlight
	# [5] Sublime text 2 - Now has a fee
	# log_debug '[5] Sublime text 2 - Now has a fee'
	# sudo add-apt-repository -y ppa:webupd8team/sublime-text-2
	# Dropbox
	log_debug 'Dropbox'
	sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
	# sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ oneiric main" >> /etc/apt/sources.list.d/dropbox.list'
	# sudo sh -c 'echo "#deb http://linux.dropbox.com/ubuntu/ precise main" >> /etc/apt/sources.list.d/dropbox.list'
	# sudo sh -c 'echo "#deb http://linux.dropbox.com/ubuntu/ quantal main" >> /etc/apt/sources.list.d/dropbox.list'
	# sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ trusty main" >> /etc/apt/sources.list.d/dropbox.list'
	sudo sh -c "echo deb http://linux.dropbox.com/ubuntu/ $stableReleaseName main >> /etc/apt/sources.list.d/dropbox-$stableReleaseName.list"
	# Boot-Repair
	log_debug 'Boot-Repair'
	sudo add-apt-repository -y ppa:yannubuntu/boot-repair
	# Brackets
	log_debug 'Brackets'
	sudo add-apt-repository -y ppa:webupd8team/brackets
	# Atom
	# log_debug 'Atom'
	# sudo add-apt-repository -y ppa:webupd8team/atom
	# Variety
	log_debug 'Variety'
	sudo add-apt-repository -y ppa:peterlevi/ppa
	# Docker
	#log_debug 'Docker'
	#sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	#sudo sh -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-$distReleaseName main" >> /etc/apt/sources.list.d/docker-$distReleaseName.list'
	# LightTable
	log_debug 'LightTable'
	sudo add-apt-repository -y ppa:dr-akulavich/lighttable
	# Sunflower
	log_debug 'Sunflower'
	sudo add-apt-repository -y ppa:atareao/sunflower

  # dekstop specific repositories
	case $desktopEnvironment in
		"kde" )
      sudo add-apt-repository -y ppa:rikmills/latte-dock
			;;
		"gnome" )
			# [4] Ambiance and Radiance Theme Color pack
			log_debug '[4] Ambiance and Radiance Theme Color pack'
			sudo add-apt-repository -y ppa:ravefinity-project/ppa
			# [?] Blue Ambiance
			log_debug '[?] Blue Ambiance'
			sudo apt-add-repository -y ppa:satyajit-happy/themes
			;;
		"ubuntu" )
			# [4] Ambiance and Radiance Theme Color pack
      log_debug '[4] Ambiance and Radiance Theme Color pack'
			sudo add-apt-repository -y ppa:ravefinity-project/ppa
			# [?] Blue Ambiance
      log_debug '[?] Blue Ambiance'
			sudo apt-add-repository -y ppa:satyajit-happy/themes
			;;
		"xubuntu" )
			;;
		"lubuntu" )
			;;
	esac

  #Change distro for some of the older PPAs
  log_debug "Change distirubtion name in repos to old versions as there has been no updates"
  changeAptSource "/etc/apt/sources.list.d/baudm-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" oneiric
  changeAptSource "/etc/apt/sources.list.d/chromium-daily-ubuntu-stable-$distReleaseName.list" "$distReleaseName" trusty
  changeAptSource "/etc/apt/sources.list.d/colingille-ubuntu-freshlight-$distReleaseName.list" "$distReleaseName" saucy
  changeAptSource "/etc/apt/sources.list.d/dlynch3-ubuntu-ppa-$distReleaseName.list" "$distReleaseName" utopic
  changeAptSource "/etc/apt/sources.list.d/librecad-dev-ubuntu-librecad-stable-$distReleaseName.list" "$distReleaseName" utopic
  changeAptSource "/etc/apt/sources.list.d/me-davidsansome-ubuntu-clementine-$distReleaseName.list" "$distReleaseName" trusty
}

  downgradeAptDistro () {
  # if [[ $distReleaseName = "xenial" || "yakkety" || "zesty" ]]; then
  if [[ "$distReleaseName" =~ ^($previousStableReleaseName|$stableReleaseName|$betaReleaseName)$ ]]; then
    log_debug "Change Repos for which there aren't new repos."
    log_debug "Change n-muench to Xenial"
    changeAptSource "/etc/apt/sources.list.d/n-muench-ubuntu-programs-ppa-$distReleaseName.list" "$distReleaseName" wily
    # log_debug "Change VLC to Xenial"
    # changeAptSource "/etc/apt/sources.list.d/n-muench-ubuntu-vlc-$distReleaseName.list" "$distReleaseName" wily
    case $desktopEnvironment in
      "kde" )
        ;;
      "gnome" )
        log_debug "Change Happy Themes to Xenial"
        changeAptSource "/etc/apt/sources.list.d/satyajit-happy-ubuntu-themes-$distReleaseName.list" "$distReleaseName" wily
        ;;
      "xubuntu" )
        ;;
      "lubuntu" )
        ;;
    esac
  fi
  if [[ "$distReleaseName" =~ ^($stableReleaseName|$betaReleaseName)$ ]]; then
    log_warning "Change $stableReleaseName and $betaReleaseName Repos for which there aren't new repos."
    log_warning "Change Sunflower to $previousStableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/atareao-ubuntu-sunflower-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    log_warning "Change Dropbox to $previousStableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/dropbox-$stableReleaseName.list" "$stableReleaseName" "$previousStableReleaseName"
    log_warning "Change Lighttable to $previousStableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/dr-akulavich-ubuntu-lighttable-$distReleaseName.list" "$distReleaseName" "$previousStableReleaseName"
    case $desktopEnvironment in
      "kde" )
        ;;
      "gnome" )
        log_warning "Change ravefinity-project to $previousStableReleaseName"
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
    sudo add-apt-repository -y ppa:mystilleef/scribes-daily
    changeAptSource "/etc/apt/sources.list.d/mystilleef-ubuntu-scribes-daily-$distReleaseName.list" "$distReleaseName" quantal
    # FreeFileSync
    log_warning 'FreeFileSync'
    sudo add-apt-repository -y ppa:freefilesync/ffs
    # wget -q -O - http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
    # sudo sh -c 'echo "deb http://archive.getdeb.net/ubuntu vivid-getdeb apps" >> /etc/apt/sources.list.d/getdeb.list'
    changeAptSource "/etc/apt/sources.list.d/freefilesync-ubuntu-ffs-$distReleaseName.list" "$distReleaseName" trusty
    # Canon Printer Drivers
  	log_warning 'Canon Printer Drivers'
  	sudo add-apt-repository -y ppa:michael-gruz/canon-trunk
  	sudo add-apt-repository -y ppa:michael-gruz/canon
  	sudo add-apt-repository -y ppa:inameiname/stable
    changeAptSource "/etc/apt/sources.list.d/michael-gruz-ubuntu-canon-trunk-$distReleaseName.list" "$distReleaseName" utopic
    changeAptSource "/etc/apt/sources.list.d/michael-gruz-ubuntu-canon-$distReleaseName.list" "$distReleaseName" quantal
    changeAptSource "/etc/apt/sources.list.d/inameiname-ubuntu-stable-$distReleaseName.list" "$distReleaseName" trusty
    # Inkscape
    log_warning 'Inkscape'
    sudo add-apt-repository -y ppa:inkscape.dev/stable
  fi
  if [[ $betaAns == 1 ]]; then
    log_warning "Beta Code, downgrade the apt sources."
    changeAptSource "/etc/apt/sources.list.d/danielrichter2007-ubuntu-grub-customizer-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-brackets-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
    changeAptSource "/etc/apt/sources.list.d/pmjdebruijn-ubuntu-darktable-release-$distReleaseName.list" "$distReleaseName" "$stableReleaseName"
  fi
}

# ############################################################################
# Install applications
installApps () {
  log_info "Start Applications installation the general apps"
	# general applications
  sudo apt install -yf
	sudo apt -yf install synaptic gparted aptitude mc filezilla remmina nfs-kernel-server nfs-common samba ssh sshfs rar gawk rdiff-backup luckybackup vim vim-gnome vim-doc bashdb ddd abs-guide tree meld cups-pdf keepassx flashplugin-installer bzr ffmpeg htop iptstate kerneltop vnstat unetbootin nmon qpdfview idle3 idle3-tools  keepnote workrave freeplane unison unison-gtk deluge-torrent liferea dia-gnome planner gimp gimp-plugin-registry rawtherapee graphicsmagick imagemagick calibre eclipse shutter easytag clementine terminator chromium-browser google-chrome-stable rapid-photo-downloader gimp-plugin-registry y-ppa-manager oracle-java9-installer darktable librecad winusb dropbox boot-repair grub-customizer brackets shellcheck variety lighttable-installer sunflower blender google-chrome-stable caffeine upstart eric eric-api-files;

  sudo snap install vlc vlc-data browser-plugin-vlc
  sudo snap install atom --classic

  # older packages that will not install on new releases
  if ! [[ "$distReleaseName" =~ ^(yakkety|zesty)$ ]]; then
   sudo apt install scribes freefilesync cnijfilter-common-64 cnijfilter-mx710series-64 scangearmp-common-64 scangearmp-mx710series-64 ufw-gtk inkscape
  fi
	# desktop specific applications
	case $desktopEnvironment in
		"kde" )
			sudo apt -y install kubuntu-restricted-addons kubuntu-restricted-extras doublecmd-qt doublecmd-help-en doublecmd-plugins digikam amarok kdf k4dirstat filelight kde-config-cron latte-dock kdesdk-dolphin-plugins;
			;;
		"gnome" )
			sudo apt -y install doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky	gufw nautilus-image-converter wallch alacarte gnome-shell-extensions-gpaste ambiance-colors radiance-colors;
			;;
		"ubuntu" )
			sudo apt -y install doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander dconf-tools ubuntu-restricted-extras gthumb gnome-raw-thumbnailer conky	gufw nautilus-image-converter wallch alacarte ambiance-colors radiance-colors;
			;;
		"xubuntu" )
			sudo apt -y install doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander;
			;;
		"lubuntu" )
			sudo apt -y install doublecmd-gtk doublecmd-help-en doublecmd-plugins gmountiso gnome-commander;
			;;
	esac
}

# ############################################################################
# Install other applications individually
installOtherApps () {
  ##### Menu section
  doUpdateUpgrade=0

  until [[ "$choice" = "q" ]]; do
    clear
    printf "



    There are the following options for installing individual apps.
    NOTE: The apps will only be installed when you quit this menu so that only one repo update is done.
    TASK : DESCRIPTION
    -----: ---------------------------------------
    v    : VirtualBox Host
    w    : VirtualBox Guest

    q       : Quit this program

    "

    read -rp "Enter your choice : " choice
    # printf "%s" "$choice"

    # take inputs and perform as necessary
    case "$choice" in
      v )
        doUpdateUpgrade=1
        installVirtualboxHost=1
      ;;
      w )
        doUpdateUpgrade=1
        installVirtualboxGuest=1
      ;;
    	q )
      	 if [[ $doUpdateUpgrade = 1 ]]; then
      	   repoUpdate
      	 fi
         if [[ $installVirtualboxHost = 1 ]]; then
           sudo apt install virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso;
            case $desktopEnvironment in
              "kde" )
                sudo apt -y virtualbox-qt;
                ;;
            esac
         fi
         if [[ $installVirtualboxGuest = 1 ]]; then
           sudo apt install virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
         fi
         exit 1
      ;;
    	*) exit 1
    		;;
    esac
  done
}

# ############################################################################
# Install settings and applications one by one by selecting options
installOptions () {
  ##### Menu section
  until [[ "$choice" = "q" ]]; do
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
    gnmb : Upgrade Gnome to Gnome on backports
    kdeb : Upgrade KDE to KDE on backports
    ignm : Install Gnome Desktop from backports
    ikde : Install KDE Desktop from backports
    disp : Install Laptop Display Drivers for Intel en Nvidia
    dslk : Install DisplayLink
    ownc : Install ownCloudClient
    chrm : Install Google Chrome browser
    dgkm : Install Digikam
    dckr : Install Docker
    fnts : Install extra fonts
    vmgs : Setup for a Vmware guest
    vbgs : Setup for a VirtualBox guest
    dtdr : Setup the home directories to link to the data disk directories

    beta: Set options for an Ubuntu Beta install with PPA references to a previous version

    q       : Quit this program

    "

    read -rp "Enter your choice : " choice
    # printf "%s" "$choice"

    # take inputs and perform as necessary
    case "$choice" in
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
      gnmb )
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
      ignm )
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
      kdeb )
        read -rp "Do you want to add the KDE Backports apt sources? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          kdeBackportsRepo
        fi
      ;;
      ikde )
        read -rp "Do you want to install KDE from the Backports? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          # kdeBackportsRepo
          kdeBackportsApps
        fi
      ;;
      disp)
    		printline_debug "%s" choice
        laptopDisplayDrivers
    		printline_success "Installed Laptop Display Drivers."
    		;;
    	dslk)
    		printline_debug "%s" "$choice"
        displayLinkInstallApp
    	;;
      ownc )
        read -rp "Do you want to install ownCloudClient? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          ownCloudClientRepo
          repoUpdate
          ownCloudClientInstallApp
        fi
      ;;
      chrm )
        read -rp "Do you want to install Google Chrome? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          googleChromeInstall
        fi
      ;;
      dgkm )
        read -rp "Do you want to install DigiKam? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          installDigikamRepo
          repoUpdate
          installDigikamApp
        fi
      ;;
      dckr )
        read -rp "Do you want to install Docker? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          # configureDockerRepo
          # repoUpdate
          configureDockerInstall
        fi
      ;;
      fnts )
        read -rp "Do you want to install extra Fonts? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          installFonts
        fi
      ;;
      vmgs )
        read -rp "Do you want to install and setup for VMware guest? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          vmwareGuestSetup
      fi
      ;;
      vbgs )
        read -rp "Do you want to install and setup for VirtualBox guest? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          virtalBoxGuestSetup
      fi
      ;;

      dtdr )
        read -rp "Do you want to update the home directory links for the data drive? (y/n)" answer
        if [[ $answer = [Yy1] ]]; then
          setupDataDirLinks
        fi
      ;;
      beta )
        printline_warning "Running $desktopEnvironment $distReleaseName $distReleaseVer"
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
              quit )
                validchoice=1
              ;;
              * )
                printline_warning "Please enter a valid choice, the first letter of the stable release you need."
                validchoice=0
              ;;
            esac
          done
        fi
      ;;
    	q )	;;
    	*) exit 1
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
    # if [[ $dockerAns = 1 ]]; then
       # configureDockerRepo
    # fi
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
    log_info 'Start Applications installation'
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
  log_info 'Start Auto Applications installation'
  noPrompt=1
  kernelUpdate
  case $1 in
    [lw] )
      ownCloudClientRepo
      # configureDockerRepo
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
log_info "Start of BuildMan"
log_info "===================================================================="
clear

# ########################################################
# Set global variables
desktopEnvironmentCheck

if [[ ("$betaReleaseName" == "$distReleaseName") || ("$betaReleaseVer" == "$distReleaseVer") ]]; then
  betaAns=1
else
  stableReleaseVer=$distReleaseVer
  stableReleaseName=$distReleaseName
fi
log_warning "distReleaseVer=$distReleaseVer"
log_warning "distReleaseName=$distReleaseName"
log_warning "stableReleaseVer=$stableReleaseVer"
log_warning "stableReleaseName=$stableReleaseName"
log_warning "betaReleaseName=$betaReleaseName"
log_warning "betaAns=$betaAns"


echo "
MESSAGE : In case of options, one value is displayed as the default value.
Do erase it to use other value.

BuildMan v0.1

This script is documented in README.md file.

Running $desktopEnvironment $distReleaseName $distReleaseVer

There are the following options for this script
TASK :     DESCRIPTION

la   : Install Laptop with all packages without asking
lq   : Install Laptop with all packages asking for groups of packages

wa   : Install Workstation with all packages without asking
wq   : Install Workstation with all packages asking for groups of packages

vma  : Install VMware VM with all packages without asking
vmq  : Install VMware VM with all packages asking for groups of packages

vba  : Install VirtualBox VM with all packages without asking
vbq  : Install VirtualBox VM with all packages asking for groups of packages

item : Install individual repos and items

q       : Quit this program

"

read -rp "Enter your choice : " choice

# if [[ $choice == 'q' ]]; then
# 	exit 0
# fi

printline_warning "Enter your system password if asked...\n"

# take inputs and perform as necessary
case "$choice" in
	la|xpsa)
  	printline_info "Automated installation for a Laptop\n"
    autoRun l
    printline_success "Operation completed successfully."
	;;
	lq|xpsq)
    printline_info "Laptop Installation asking items:\n"
    questionRun l
    printline_success "Operation completed successfully.\n"
	;;
	wa)
  	printline_info "Automated installation for a Workstation\n"
    autoRun w
    printline_success "Operation completed successfully.\n"
	;;
	wq)
    printline_info "Workstation Installation asking items:\n"
    questionRun w
    printline_success "Operation completed successfully.\n"
	;;
	vma)
    printline_info "Automated install for a Vmware virtual machine\n"
    autoRun vm
    printline_success "Operation completed successfully.\n"
  ;;
  # ############################################################################
	vmq|vm-question)
    log_info "Vmware install asking questions as to which apps to install for the run"
    printline_warning "Vmware install asking questions as to which apps to install for the run"
    questionRun vm
  ;;
  # ############################################################################
	vba|vb-all)
    printline_info "Automated install for a VirtualBox virtual machine\n"
    autoRun vb
    printline_success "Operation completed successfully.\n"
  ;;
  # ############################################################################
  vbq|vb-question)
    log_info "VirtualBox install asking questions as to which apps to install for the run"
    printline_warning "VirtualBox install asking questions as to which apps to install for the run"
    questionRun vb
  ;;
	item )
  	printline_info "Selecting itemized installations"
    installOptions
  ;;
  q);;
  *) exit
  ;;
esac

log_info "Job done!"
log_info "End of BuildMan"
log_info "===================================================================="

printline_info "Job done!"
printline_info "Thanks for using. :-)"
# ############################################################################
# set debugging off
set -xv

exit;
