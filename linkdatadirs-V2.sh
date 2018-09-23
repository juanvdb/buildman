#! /bin/bash

# Remove existing files.

MOUNTDIR=$1
HOMEDIR="$MOUNTDIR/home/$USER"
DATADIR="/data"

INTERACTIVE_MODE="on"
scriptDebugToStdout="on"
scriptDebugToFile="on"
debugLogFile="$MOUNTDIR/tmp/linkdatafiles.log"
errorLogFile="$MOUNTDIR/tmp/linkdatafileserror.log"

linkDataDirectories=(
"bin"
"Development"
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
initialiseLogs() {
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
}

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

checkParameters() {
  if [[ -z "${1// }" ]]; then
    printf "You did not specify a mounted target directory. You can enter it as a parameter next time or enter one now.\n"
    printf "link-data-dotfiles-to-home_from_boot_diskV3.sh /media/%s/newubuntu\n" "${USER}"
    read -rp "Please enter the mounted directory of the new OS, for example /media/${USER}/newos:" answer
    MOUNTDIR=$answer
  fi
  HOMEDIR="$MOUNTDIR/home/$USER"
  # ETCDIR="$MOUNTDIR/etc"
  printf "\nThe target home directory is: %s\n" "$HOMEDIR"
  printf "\nThe source data directory for HOME is: %s" "${DATADIR}"
  read -rp "Please press enter to keep ${dotFilesParentDir} or enter a new directory: " answer
  if [[ ! -z "${answer// }" ]]; then
    if [[ -d ${answer} ]]; then
      dotFilesParentDir=${answer}
    else
      die "Please enter a valid directory."
    fi
  fi
  printf "\nThe source dotfiles directory for etc is: %s" "${etcFilesParentDir}"
  read -rp "Please press enter to keep ${etcFilesParentDir} or enter a new directory: " answer
  if [[ ! -z "${answer// }" ]]; then
    if [[ -d ${answer} ]]; then
      etcFilesParentDir=${answer}
    else
      die "Please enter a valid directory."
    fi
  fi
}

linkDataDir() {
    if [ -d "$HOMEDIR/data" ]; then
      if [ -L "$HOMEDIR/data" ]; then
        # It is a symlink!
        log_info "Keep symlink $HOMEDIR/data"
      else
        # It's a directory!
        log_warning "Remove directory $HOMEDIR/data"
        rm -R "${HOMEDIR/data:?}"
        ln -s "$DATADIR" "$HOMEDIR/data"
      fi
    else
      log_info "Link directory $HOMEDIR/data"
      ln -s "$DATADIR" "$HOMEDIR/data"
    fi
}

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
        rm -R "${HOME/$sourceDataDirectory:?}"
        ln -s "$DATADIR" "$HOMEDIR/$sourceDataDirectory"
      fi
    else
      log_debug "Link directory $HOMEDIR/data"
      ln -s "$DATADIR" "$HOMEDIR/$sourceDataDirectory"
    fi

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
            rm "$HOMEDIR/$sourceLinkDirectory"
            ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
            # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          else
            # It's a directory!
            # log_debug "Remove directory $HOMEDIR/data"
            rmdir "$HOMEDIR/$sourceLinkDirectory"
            ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
            # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          fi
        else
          rm "$HOMEDIR/$sourceLinkDirectory"
          ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
        fi
      else
        # log_debug "$HOMEDIR/$sourceLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOMEDIR/$sourceLinkDirectory" ];  then
          # It is a symlink!
          # log_debug "Remove symlink $HOMEDIR/$sourceLinkDirectory"
          rm "$HOMEDIR/$sourceLinkDirectory"
          ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
          # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory $HOMEDIR/$sourceLinkDirectory"
        fi
        ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$sourceLinkDirectory"
        # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory $HOMEDIR/$sourceLinkDirectory"
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
      # mkdir -p "$DATADIR/$sourceLinkDirectory"
      # up to here
      # log_debug "sourceLinkDirectoryLink directory = $sourceLinkDirectory; targetLinkDirectory = $targetLinkDirectory"
      if [ -e "$HOMEDIR/$targetLinkDirectory" ]; then
        if [ -d "$HOMEDIR/$targetLinkDirectory" ]; then
          if [ -L "$HOMEDIR/$targetLinkDirectory" ]; then
            # It is a symlink!
            # log_debug "Remove symlink $HOMEDIR/$targetLinkDirectory"
            rm "$HOMEDIR/$targetLinkDirectory"
            ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
            # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          else
            # It's a directory!
            # log_debug "Remove directory $HOMEDIR$DATADIR"
            rmdir "$HOMEDIR/$targetLinkDirectory"
            ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
            # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          fi
        else
          rm "$HOMEDIR/$targetLinkDirectory"
          ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
        fi
      else
        # log_debug "$HOMEDIR/$targetLinkDirectory does not exists and synlink will be made"
        if [ -L "$HOMEDIR/$targetLinkDirectory" ];  then
          # It is a symlink!
          # log_debug "Remove symlink $HOMEDIR/$targetLinkDirectory"
          rm "$HOMEDIR/$targetLinkDirectory"
          ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
          # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory $HOMEDIR/$targetLinkDirectory"
        fi
        ln -s "$DATADIR/$sourceLinkDirectory" "$HOMEDIR/$targetLinkDirectory"
        # log_debug "Create symlink directory ln -s $DATADIR/$sourceLinkDirectory $HOMEDIR/$targetLinkDirectory"
      fi
    done

  #   # For Firefox only
  #   if [[ "$noPrompt" -eq 0 ]]; then
  #     read -rp "Do you want to link to Data's Firefox (y/n): " qfirefox
  #     if [[ $qfirefox = [Yy1] ]]; then
  #       sourceLinkDirectory="$HOMEDIR/.mozilla"
  #       if [ -d "$sourceLinkDirectory" ]; then
  #         rm -R "$sourceLinkDirectory"
  #         ln -s $DATADIR/.mozilla "$sourceLinkDirectory"
  #       fi
  #     fi
  #   else
  #     sourceLinkDirectory"$HOMEDIR/.mozilla"
  #     if [ -d "$sourceLinkDirectory" ]; then
  #       rm -R "$sourceLinkDirectory"
  #       ln -s $DATADIR/.mozilla "$sourceLinkDirectory"
  #     fi
  #   fi
  fi
  cd "$currentPath" || exit
}

# Main
checkParameters "$1"
initialiseLogs
linkDataDir
dataDirLinksSetup

cd "$currentPath" || exit
exit
