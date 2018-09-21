#! /bin/bash

# ############################################################################
# ==> set global Variables
betaReleaseName="artful"
betaReleaseVer="17.10"
stableReleaseName="zesty"
stableReleaseVer="17.04"
previousStableReleaseName="yakkety"
ltsReleaseName="xenial"
desktopEnvironment=""
kernelRelease=$(uname -r)
distReleaseVer=$(lsb_release -sr)
distReleaseName=$(lsb_release -sc)
noPrompt=0
debugLogFile="dirdatadebug.log"
errorLogFile="dirdataerror.log"

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
    echo -en "\n" >>$debugLogFile
    echo -en "\033[1;31m##############################################################\n\033[0m" >>$debugLogFile
    echo -en "\n" >>$debugLogFile
    echo -en "\033[1;31m START OF NEW RUN\n\033[0m" >>$debugLogFile
    echo -en "\n" >>$debugLogFile
    echo -en "\033[1;31m###############################################################\n\033[0m" >>$debugLogFile
    echo -en "\n" >>$debugLogFile
  else
    touch $debugLogFile
  fi
  if [[ -e $errorLogFile ]]; then
    # >$errorLogFile
    echo -en "\n"
    echo -en "\033[1;31m###############################################################\n\033[0m" >>$errorLogFile
    echo -en "\n" >>$errorLogFile
    echo -en "\033[1;31m START OF NEW RUN\n\033[0m" >>$errorLogFile
    echo -en "\n" >>$errorLogFile
    echo -en "\033[1;31m###############################################################\n\033[0m" >>$errorLogFile
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



log_info "XPS Data Dir links"
currentPath=$(pwd)
cd "$HOME" || exit

###############################################################################################################

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
  ".mozilla"
  "bin"
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
    mkdir -p "/data/$sourceLinkDirectory"
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


#   # For Firefox only
#   if [[ "$noPrompt" -ne 1 ]]; then
#     read -rp "Do you want to link to Data's Firefox (y/n): " qfirefox
#     if [[ $qfirefox = [Yy1] ]]; then
#       sourceLinkDirectory=~/.mozilla
#       if [ -d "$sourceLinkDirectory" ]; then
#         rm -R "$sourceLinkDirectory"
#         ln -s /data/.mozilla "$sourceLinkDirectory"
#       fi
#     fi
#   else
#     sourceLinkDirectory=~/.mozilla
#     if [ -d "$sourceLinkDirectory" ]; then
#       rm -R "$sourceLinkDirectory"
#       ln -s /data/.mozilla "$sourceLinkDirectory"
#     fi
#   fi
# fi


###############################################################################################################


cd "$currentPath" || exit
