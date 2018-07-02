#!/bin/bash

# DateVer 2018/06/12
# Buildman V1.9
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
  debugLogFile="loggingtest.log"
  errorLogFile="loggingtest_error.log"

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
scriptDebugToStdout="on"
scriptDebugToFile="on"
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

log_info()            { log "$@"; }
log_success()         { log "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
log_error()           { log "$1" "ERROR" "${LOG_ERROR_COLOR}"; }
log_warning()         { log "$1" "WARNING" "${LOG_WARN_COLOR}"; }
log_debug()           { log "$1" "DEBUG" "${LOG_DEBUG_COLOR}"; }
log_info_banner()     { log "$1" "" "$LOG_BANNER_GREY"; }
log_debug_banner ()   { log "$1" "DEBUG" "${LOG_BANNER_BLUE}"; }
log_warning_banner () { log "$1" "WARNING" "${LOG_BANNER_YELLOW}"; }

println() {
  local println_text="$1"
  local println_color="$2"

  # Default level to "info"
  [[ -z ${println_color} ]] && println_color="${LOG_INFO_COLOR}";

  echo -e "${println_color} ${println_text} ${LOG_DEFAULT_COLOR}";
  return 0;
}

println_info()            { println "$@"; }
println_banner_yellow()   { println "$1" "${LOG_BANNER_YELLOW}"; }
println_banner_blue()     { println "$1" "${LOG_BANNER_BLUE}"; }
println_red()             { println "$1" "${LOG_ERROR_COLOR}"; }
println_yellow()          { println "$1" "${LOG_WARN_COLOR}"; }
println_blue()            { println "$1" "${LOG_DEBUG_COLOR}"; }


# ############################################################################
#--------------------------------------------------------------------------------------------------


# ############################################################################
# Die process to exit because of a failure
die() { echo "$*" >&2; exit 1; }

# main
main () {
  log_info "Log Info"
  log_success "Log Success"
  log_error "Log Error"
  log_warning "Log Warning"
  log_debug "Log Debug"
  log_info_banner "Log Info Banner"
  log_debug_banner "Log Debug Banner"
  log_warning_banner "Log Warning Banner"
  echo -en "\n"
  println_info "Println Info"
  println_banner_yellow "Println Bannner Yellow"
  println_banner_blue "Println Banner Blue"
  println_red "Println Red"
  println_yellow "Println Yellow"
  println_blue "Println Blue"
}

#Run time code

main;
exit;
