#!/usr/bin/env sh
# shellcheck disable=SC1090
###############################################################################
## talos - test and run automation
##
## this tool is designed to aide in the standardisation of builds, tests and
## the running of software projects
##
## principles:
## - optimise portability for *nix
## - docker dependent
## - opinionated but extendable
###############################################################################
# help: build, test and run automation tool
set -eu

TALOS_IMAGE="${TALOS_IMAGE:-pemcconnell/talos:latest}"
# shellcheck disable=SC2012
SCRIPT_PATH="$(ls -l "$0" | awk '{print $NF}')"
TALOS_DIR="$(echo "$SCRIPT_PATH" | sed -e "s/\\(.*\\/\\)[^\\/]*$/\\1/")"
TALOS_DIR="$(cd "$TALOS_DIR" && pwd)/"
SRC_DIR="${TALOS_DIR}cmds/"
IN_DOCKER="${IN_DOCKER:-False}"
IGNORE_IN_DOCKER="${IGNORE_IN_DOCKER:-False}"
NOCOLOR="${NOCOLOR:-False}"
DEBUG="${DEBUG:-False}"
if [ ! "${PROJECT_ROOT+x}" ]; then
  # attempt to find project root dynamically
  PROJECT_ROOT="./"
  while true; do
    abs="$(cd "$PROJECT_ROOT" && pwd)"
    if [ "$abs" = "/" ]; then
      PROJECT_ROOT="$(pwd)/"
      break
    fi
    if [ ! -f "${PROJECT_ROOT}.talos/config.sh" ]; then
      PROJECT_ROOT="../$PROJECT_ROOT"
    else
      PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)/"
      break
    fi
  done
fi

if [ "$DEBUG" = "x" ]; then
  set -x
fi

# shellcheck disable=SC1091
. "${TALOS_DIR}libs/help.sh"  # help() function

FLAG_help="${FLAG_help:-False}"

_print() {
  if [ "$NOCOLOR" = "False" ]; then
    printf " [ $1%-10s\\033[0m] %s\\n" "$2" "$3"
  else
    printf " [ %-10s] %s\\n" "$2" "$3"
  fi
}
_heading() {
  printf " %s\\n" "$1"
}
_subheading() {
  _heading "- $1"
}
_debug() {
  if [ "$DEBUG" != "False" ]; then
    _print "\\033[36m" "debug" "$1"
  fi
}
_warn() {
  >&2 _print "\\033[33m" "warn" "$1"
}
_info() {
  _print "\\033[32m" "info" "$1"
}
_error() {
  >&2 _print "\\033[31m" "error" "$1"
}


if [ "${1+x}" ]; then
  cmd="$(echo "$*" | sed -e "s/[\\.\\/]//g")"
  flags="$(echo "$*" | grep -o -e " --[^ ]*" || true)"
  flags="$(echo "$flags" | sed -e "s/ --//g")"
  cmd="$(echo "$*" | sed -e "s/ --[^ ]*//g")"
  if [ "$flags" != "" ]; then
    for flag in $flags; do
      if ! echo "$flag" | grep -q "="; then  # flag has a value
        flag="${flag}=True"
      fi
      eval "FLAG_$flag"
    done
  fi
  if [ -f "${PROJECT_ROOT}.talos/config.sh" ]; then
    _debug "loading project config"
    . "${PROJECT_ROOT}.talos/config.sh"
  else
    _debug "no project config found. skipping"
  fi
  if [ "$IGNORE_IN_DOCKER" = "False" ] && \
     [ "$cmd" != "docker" ] && \
     [ "$IN_DOCKER" = "False" ]; then
    (. "${SRC_DIR}docker/run.sh"; IN_DOCKER=True FLAG_cmd="talos $*" FLAG_tag="$TALOS_IMAGE" main)
    exit 0
  fi
  cmdpath=""
  if [ -f "${PROJECT_ROOT}.talos/cmds/$(echo "$cmd" | tr ' ' '/')}.sh" ]; then
    _debug "loading custom command $cmd"
    cmdpath="${PROJECT_ROOT}.talos/cmds/$(echo "$cmd" | tr ' ' '/').sh"
  elif [ -f "${SRC_DIR}$(echo "$cmd" | tr ' ' '/').sh" ]; then
    cmdpath="${SRC_DIR}$(echo "$cmd" | tr ' ' '/').sh"
  fi
  if [ "$cmdpath" = "" ]; then
    _error "command not found"
    exit 1
  fi
  if [ "$FLAG_help" = "True" ]; then
    _debug "loading custom command help for $cmd"
    help "$cmdpath" "$cmd"
    exit 0
  fi
  . "$cmdpath"  # load command
  if type main > /dev/null; then
    main
  fi
else
  help
fi
