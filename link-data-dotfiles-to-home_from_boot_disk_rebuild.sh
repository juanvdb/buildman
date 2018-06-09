#! /bin/bash

# Remove existing files.

MOUNTDIR=$1
HOMEDIR="$MOUNTDIR/home/juan"
dotFilesParentDir="/data/dotfiles/home"
etcFilesParentDir="/data/dotfiles/etc"
ETCDIR="$MOUNTDIR/etc"

INTERACTIVE_MODE="on"
scriptDebugToStdout="on"
scriptDebugToFile="on"
debugLogFile="linkdotfiles.log"
errorLogFile="linkdotfileserror.log"

dotFilesList=(
".bash_aliases"
".bash_history"
".bash_profile"
".bashrc"
".config"
".dropbox"
".dropbox-dist"
".easy-ebook-viewer.conf"
"eclipse"
".eclipse"
".face"
".gconf"
".gem"
".gitconfig"
".gitignore"
".gitkraken"
"GPGKey.bin"
"GPGKey.txt"
".kde"
".lastpass"
".m2"
".mime.types"
".netrc"
".oc"
".pki"
"Release.key"
".remmina"
"snap"
".ssh"
".vim"
".viminfo"
".vimrc"
".vimrc.after"
".vmware"
".webex"
".workrave"
)

etcFilesList=(
"auto.jupiter.nfs"
"auto.neptune0.nfs"
"exports"
"hosts"
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
    die "Please enter the mounted directory of the new OS, for example /media/yourname/newos"
  fi
  if [[ -z "${MOUNTDIR// }" ]]; then
    die "Please enter the mounted directory of the new OS, for example /media/yourname/newos"
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
        ln -s "/data" "$HOMEDIR/data"
      fi
    else
      log_info "Link directory $HOMEDIR/data"
      ln -s "/data" "$HOMEDIR/data"
    fi
}

linkDotFiles() {
  log_info "Link dotfiles to $dotFilesParentDir"
  currentPath=$(pwd)

  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    linkDataDir
    # log_info "dotFilesList ${dotFilesList[*]}"

    for dotSourceLink in "${dotFilesList[@]}"; do
      println_banner_yellow "Link directory = $dotSourceLink"
      log_info "Link directory = $dotSourceLink"
      # remove after testing
      # mkdir -p "$dotFilesParentDir/$dotSourceLink"
      # up to here
      if [ -e "$HOMEDIR/$dotSourceLink" ]; then
        if [ -d "$HOMEDIR/$dotSourceLink" ]; then
          if [ -L "$HOMEDIR/$dotSourceLink" ]; then
            # It is a symlink!
            log_info "Remove symlink $HOMEDIR/$dotSourceLink"
            rm "$HOMEDIR/$dotSourceLink"
            ln -s "$dotFilesParentDir/$dotSourceLink" "$HOMEDIR/$dotSourceLink"
            log_info "Create symlink directory ln -s $dotFilesParentDir/$dotSourceLink" "$HOMEDIR/$dotSourceLink"
          else
            # It's a directory!
            log_warning "Remove directory ${HOMEDIR:?}/$dotSourceLink"
            rm -rf "${HOMEDIR:?}/$dotSourceLink"
            ln -s "$dotFilesParentDir/$dotSourceLink" "$HOMEDIR/$dotSourceLink"
            log_info "Create symlink directory ln -s $dotFilesParentDir/$dotSourceLink" "$HOMEDIR/$dotSourceLink"
          fi
        else
          log_warning "Remove file $HOMEDIR/$dotSourceLink"
          rm "$HOMEDIR/$dotSourceLink"
          log_info "Create symlink directory ln -s $dotFilesParentDir/$dotSourceLink $HOMEDIR/$dotSourceLink"
          ln -s "$dotFilesParentDir/$dotSourceLink" "$HOMEDIR/$dotSourceLink"
        fi
      else
        log_info "$HOMEDIR/$dotSourceLink does not exists and synlink will be made"
        if [ -L "$HOMEDIR/$dotSourceLink" ];  then
          # It is a symlink!
          log_warning "Remove symlink $HOMEDIR/$dotSourceLink"
          rm "$HOMEDIR/$dotSourceLink"
          ln -s "$dotFilesParentDir/$dotSourceLink" "$HOMEDIR/$dotSourceLink"
          log_info "Create symlink directory ln -s $dotFilesParentDir/$dotSourceLink $HOMEDIR/$dotSourceLink"
        else
          ln -s "$dotFilesParentDir/$dotSourceLink" "$HOMEDIR/$dotSourceLink"
          log_info "Create symlink directory ln -s $dotFilesParentDir/$dotSourceLink $HOMEDIR/$dotSourceLink"
        fi
      fi
    done
  fi
}

linkEtcFiles() {
  log_info "Link  /etc files to $etcFilesParentDir"
  currentPath=$(pwd)

  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    linkDataDir
    # log_info "etcFilesList ${etcFilesList[*]}"

    for etcSourceLinkFile in "${etcFilesList[@]}"; do
      println_banner_yellow "Link etc file = $etcSourceLinkFile"
      log_info "Link etc file = $etcSourceLinkFile"
      # remove after testing
      # mkdir -p "$etcFilesParentDir/$etcSourceLinkFile"
      # up to here
      if [ -e "$ETCDIR/$etcSourceLinkFile" ]; then
        if [ -d "$ETCDIR/$etcSourceLinkFile" ]; then
          if [ -L "$ETCDIR/$etcSourceLinkFile" ]; then
            # It is a symlink!
            log_info "Remove symlink $ETCDIR/$etcSourceLinkFile"
            sudo rm "$ETCDIR/$etcSourceLinkFile"
            sudo ln -s "$etcFilesParentDir/$etcSourceLinkFile" "$ETCDIR/$etcSourceLinkFile"
            log_info "Create symlink directory ln -s $etcFilesParentDir/$etcSourceLinkFile" "$ETCDIR/$etcSourceLinkFile"
          else
            # It's a directory!
            log_warning "Remove directory ${ETCDIR:?}/$etcSourceLinkFile"
            sudo rm -rf "${ETCDIR:?}/$etcSourceLinkFile"
            sudo ln -s "$etcFilesParentDir/$etcSourceLinkFile" "$ETCDIR/$etcSourceLinkFile"
            log_info "Create symlink directory ln -s $etcFilesParentDir/$etcSourceLinkFile" "$ETCDIR/$etcSourceLinkFile"
          fi
        else
          log_warning "Remove file $ETCDIR/$etcSourceLinkFile"
          sudo rm "$ETCDIR/$etcSourceLinkFile"
          log_info "Create symlink directory ln -s $etcFilesParentDir/$etcSourceLinkFile $ETCDIR/$etcSourceLinkFile"
          sudo ln -s "$etcFilesParentDir/$etcSourceLinkFile" "$ETCDIR/$etcSourceLinkFile"
        fi
      else
        log_info "$ETCDIR/$etcSourceLinkFile does not exists and synlink will be made"
        if [ -L "$ETCDIR/$etcSourceLinkFile" ];  then
          # It is a symlink!
          log_warning "Remove symlink $ETCDIR/$etcSourceLinkFile"
          rm "$ETCDIR/$etcSourceLinkFile"
          ln -s "$etcFilesParentDir/$etcSourceLinkFile" "$ETCDIR/$etcSourceLinkFile"
          log_info "Create symlink directory ln -s $etcFilesParentDir/$etcSourceLinkFile $ETCDIR/$etcSourceLinkFile"
        else
          sudo ln -s "$etcFilesParentDir/$etcSourceLinkFile" "$ETCDIR/$etcSourceLinkFile"
          log_info "Create symlink directory ln -s $etcFilesParentDir/$etcSourceLinkFile $ETCDIR/$etcSourceLinkFile"
        fi
      fi
    done
  fi
}

linkGrubDefault() {
  log_info "Link  /etc files to $etcFilesParentDir"
  currentPath=$(pwd)

  if [ -d "/data" ]; then
    sourceDataDirectory="data"
    grubFile="/etc/default/grub"

    println_banner_yellow "Link grub file = $grubFile"
    log_info "Link grub file = $grubFile"
    if [ -e "$grubFile" ]; then
      if [ -L "$grubFile" ]; then
        # It is a symlink!
        log_info "Keep symlink $grubFile"
      else
        # It's a file!
        log_warning "Remove file $grubFile"
        sudo rm "${grubFile:?}"
        sudo ln -s "$ETCDIR/default/grub" "$grubFile"
        log_info "Create symlink grub file ln -s $ETCDIR/default/grub $grubFile"
      fi
    else
      log_info "Link grub file = $grubFile"
      sudo ln -s "$ETCDIR/default/grub" "$grubFile"
      log_info "Create symlink grub file ln -s $ETCDIR/default/grub $grubFile"
    fi
  fi
}

# Main
checkParameters "$1"
initialiseLogs
linkDataDir
linkGrubDefault
linkDotFiles
linkEtcFiles

cd "$currentPath" || exit
exit
