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
debugLogFile="desktopdebug.log"
errorLogFile="desktoperror.log"

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
    # >>$errorLogFile
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


# ############################################################################
#--------------------------------------------------------------------------------------------------


# ############################################################################
# Die process to exit because of a failure
die() { echo "$*" >&2; exit 1; }



# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
# O                   Window Managers Backports                              O
# OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
############################################################################
# Desktop environment check and return desktop environment
desktopEnvironmentCheck () {
  log_info "Desktop environment check"
  println_banner_yellow "Desktop environment check                                            "
	# another way for ssh terminals

	if [[ "$XDG_CURRENT_DESKTOP" = "" ]];
	then
    # shellcheck disable=SC2001
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
      desktopEnvironment="DON'T KNOW"
      ;;
  esac
}

desktopEnvironmentCheck
println_red "desktopEnvironment = $desktopEnvironment"
