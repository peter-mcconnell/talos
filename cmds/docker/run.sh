#!/usr/bin/env sh
# help: docker run/docker-compose up
# flags:
# --cmd | optional. set the command
# --tag | optional. define which docker image:tag you wish to run

set -eu


TALOS_IMAGE="${TALOS_IMAGE:-pemcconnell/talos:latest}"
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-./docker-compose.yml}"
DOCKER_TAG="${DOCKER_TAG:-${TALOS_IMAGE}}"
DOCKER_CMD="${DOCKER_CMD:-}"
DOCKER_FILE="${DOCKER_FILE:-./Dockerfile}"
DOCKER_CONTEXT="${DOCKER_CONTEXT:-.}"
DOCKER_PROGRESS="${DOCKER_PROGRESS:-plain}"
DOCKER_WORKSPACE="${DOCKER_WORKSPACE:-$(pwd)}"
DOCKER_EXT_ENVS="${DOCKER_EXT_ENVS:-}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)/"
if [ "$PROJECT_ROOT" = "//" ]; then
  PROJECT_ROOT="/"
fi
HOME_DIR="${HOME_DIR:-$HOME}"
DISPLAY="${DISPLAY:-}"
DOCKER_VOLUMES_EXT="${DOCKER_VOLUMES_EXT:-}"
PYTHONPATH="${PYTHONPATH:-.}"
EXT_FLAGS="${EXT_FLAGS:-}"

# flags
FLAG_cmd="${FLAG_cmd:-}"
FLAG_tag="${FLAG_tag:-}"

_volumes() {
  # helper method to build a string containing volume references
  # note this is just a convenience. mounting some of this into a container
  # could be a security risk. review and overwrite as required
  allvols="$(cat << EOF
/var/run/docker.sock:/var/run/docker.sock
$PROJECT_ROOT:$PROJECT_ROOT
/tmp/.X11-unix:/tmp/.X11-unix
${HOME_DIR}/.aws:${HOME_DIR}/.aws:ro
${HOME_DIR}/.gcr:${HOME_DIR}/.gcr:ro
${HOME_DIR}/.azure:${HOME_DIR}/.azure:ro
${HOME_DIR}/.docker:${HOME_DIR}/.docker:ro
${HOME_DIR}/.jfrog:${HOME_DIR}/.jfrog:ro
${HOME_DIR}/.terraform:${HOME_DIR}/.terraform:ro
${HOME_DIR}/.ssh:${HOME_DIR}/.ssh:ro
$DOCKER_VOLUMES_EXT
EOF
)"
  vols=""
  for vol in $allvols; do
    path="$(echo "$vol" | sed -e "s/^\\([^:]*\\).*$/\\1/")"
    if [ "$path" = "/" ]; then
      _debug "skipping / volume mount attempt"
      continue
    fi
    if [ -e "$path" ]; then
      vols="$vols -v $vol"
    fi
  done
  echo "$vols"
}

_envs() {
  # helper method to build a string containing environment variables
  allenvs="$(cat <<EOF
DISPLAY=$DISPLAY
HOST_HOME=$HOME_DIR
PROJECT_ROOT=$PROJECT_ROOT
PYTHONPATH=$PYTHONPATH
DEBUG=$DEBUG
IN_DOCKER=$IN_DOCKER
$DOCKER_EXT_ENVS
EOF
)"
  envs=""
  for env in $allenvs; do
    if [ "$env" != "" ]; then
      envs="$envs -e $env"
    fi
  done
  echo "$envs"
}

main() {
  _debug "running ..."
  extflags="$EXT_FLAGS"
  if [ "${1+x}" ]; then
    extflags="$extflags $(echo "$1" | grep -o " -[a-z]\+ \+[^ ]\+" || true)"
  fi
  cmd="$DOCKER_CMD"
  if [ "$FLAG_cmd" != "" ]; then
    cmd="$FLAG_cmd"
  fi
  if [ "$FLAG_tag" != "" ] || [ -f "$DOCKER_FILE" ]; then
    image="$DOCKER_TAG"
    if [ "$FLAG_tag" != "" ]; then
      image="$FLAG_tag"
    fi
    _debug "running docker run --rm $(_envs) $(_volumes) -w $DOCKER_WORKSPACE -ti $image $cmd"
    # shellcheck disable=SC2046,SC2086
    docker run --rm \
      $(_envs) \
      $(_volumes) \
      -w "$DOCKER_WORKSPACE" \
      $extflags \
      -ti "$image" $cmd
  elif [ -f "$DOCKER_COMPOSE_FILE" ]; then
    _debug "found docker-compose file. running ..."
    # shellcheck disable=SC2046
    _debug "running docker-compose -f $DOCKER_COMPOSE_FILE up"
    docker-compose -f "$DOCKER_COMPOSE_FILE" up
  else
    _error "not sure what to run?"
    exit 1
  fi
}
