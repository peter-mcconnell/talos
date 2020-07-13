#!/usr/bin/env sh
# shellcheck disable=SC2059
# help: get environment information

set -e

LOOK_FOR="${LOOK_FOR:-docker docker-compose bash bats python3 radon bandit pylint flake8 shellcheck hadolint go golint gosec}"


main() {
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
}
