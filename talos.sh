#!/usr/bin/env sh
# shellcheck disable=SC1090,SC2059
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

set -eu

TALOS_IMAGE="${TALOS_IMAGE:-pemcconnell/talos:latest}"
LOOK_FOR="${LOOK_FOR:-docker docker-compose bash bats python3 radon bandit pylint flake8 shellcheck hadolint}"
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

FLAG_help="${FLAG_help:-False}"

help() {
  echo "----------------------------------------------------------------------"
  color="\\033[36m"
  if [ "$NOCOLOR" = "True" ]; then
    color=""
  fi
  printf "$color%-20s\\033[0m %s\\n" \
    "help" "display all options"
  printf "$color%-20s\\033[0m %s\\n" \
    "info" "display talos information for current working directory"
  cmddirs="${PROJECT_ROOT}.talos/cmds/ $SRC_DIR"
  cmdcache=""
  for cmddir in $cmddirs; do
    if [ -d "$cmddir" ]; then
      # shellcheck disable=SC2044
      for file in $(find "$cmddir" -type f -name "*.sh"); do
        name="$(echo "$file" | sed -e "s/^.*\\/\\([^\\/]*\\).sh$/\\1/")"
        if echo "$cmdcache" | grep -q "@$name@"; then
          _debug "command already found. first come first served. skipping"
          continue
        fi
        cmdcache="${cmdcache}@$name@"
        desc="$(head -n 10 "$file" | grep "# help: " | sed -e "s/^.*help: //")"
        printf "$color%-20s\\033[0m %s\\n" "$name" "$desc"
      done
    fi
  done
}

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
  cmd="$(echo "$1" | sed -e "s/[\\.\\/]//g")"
  flags="$(echo "$*" | grep -o -e " --[^ ]*" || true)"
  flags="$(echo "$flags" | sed -e "s/ --//g")"
  if [ "$flags" != "" ]; then
    for flag in $flags; do
      if ! echo "$flag" | grep -q "="; then  # flag has a value
        flag="${flag}=True"
      fi
      eval "FLAG_$flag"
    done
  fi
  if [ "$cmd" = "help" ]; then
    help
    exit 0
  fi
  if [ -f "${PROJECT_ROOT}.talos/config.sh" ]; then
    _debug "loading project config"
    . "${PROJECT_ROOT}.talos/config.sh"
  else
    _debug "no project config found. skipping"
  fi
  if [ "$IGNORE_IN_DOCKER" = "False" ] && \
     [ "$cmd" != "docker" ] && \
     [ "$FLAG_help" = "False" ] && \
     [ "$IN_DOCKER" = "False" ]; then
    export NOEXEC=1
    . "${SRC_DIR}docker.sh"
    IN_DOCKER=True docker_run "talos $*" "$TALOS_IMAGE"
    exit 0
  fi
  if [ "$cmd" = "info" ]; then
    cat <<EOF
vars
-------------------------------------------------------------------------------
TALOS_IMAGE=$TALOS_IMAGE
PROJECT_ROOT=$PROJECT_ROOT
SCRIPT_PATH=$SCRIPT_PATH
TALOS_DIR=$TALOS_DIR
SRC_DIR=$SRC_DIR
NOCOLOR=$NOCOLOR
IN_DOCKER=$IN_DOCKER
DEBUG=$DEBUG

environment info
-------------------------------------------------------------------------------
whoami: $(whoami)
EOF
    found="\\033[32m"
    notfound="\\033[31m"
    if [ "$NOCOLOR" = "True" ]; then
      found=
      notfound=
    fi
    nc="\\033[0m"
    for bin in $LOOK_FOR; do
      printf "%s ..." "$bin"
      if command -v "$bin" > /dev/null; then
        printf " ${found}installed"
      else
        printf " ${notfound}not found!"
      fi
      printf "${nc}\\n"
    done
  else
    if [ -f "${PROJECT_ROOT}.talos/cmds/${cmd}.sh" ]; then
      _debug "loading custom command $cmd"
      . "${PROJECT_ROOT}.talos/cmds/${cmd}.sh"
    else
      if [ -f "${SRC_DIR}${cmd}.sh" ]; then
        . "${SRC_DIR}${cmd}.sh"
      else
        _error "command not found"
        exit 1
      fi
    fi
  fi
else
  help
fi
