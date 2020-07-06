#!/usr/bin/env sh
# help: perform project-relevant docker commands

set -eu


DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-./docker-compose.yml}"
DOCKER_TAG="${DOCKER_TAG:-test}"
DOCKER_FILE="${DOCKER_FILE:-./Dockerfile}"
DOCKER_CONTEXT="${DOCKER_CONTEXT:-.}"
DOCKER_PROGRESS="${DOCKER_PROGRESS:-plain}"
DOCKER_WORKSPACE="${DOCKER_WORKSPACE:-$(pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)/"
HOME_DIR="${HOME_DIR:-$HOME}"
DOCKER_VOLUMES_EXT="${DOCKER_VOLUMES_EXT:-}"


# help is the default entrypoint
help() {
    printf "\033[36m%-20s\033[0m %s\n" "build" "docker build/docker-compose build"
    printf "\033[36m%-20s\033[0m %s\n" "run" "docker run/docker-compose up"
}

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
    path="$(echo "$vol" | sed -e "s/^\([^:]*\).*$/\1/")"
    if [ -e "$path" ]; then
      vols="$vols -v $vol"
    fi
  done
  echo "$vols"
}

_envs() {
  # helper method to build a string containing environment variables
  allenvs="$(cat <<EOF
DISPLAY=unix$DISPLAY
HOST_HOME=$HOME_DIR
PROJECT_ROOT=$PROJECT_ROOT
EOF
)"
  envs=""
  for env in $allenvs; do
    envs="$envs -e $env"
  done
  echo "$envs"
}

build() {
  _debug "building ..."
  if [ -f "$DOCKER_COMPOSE_FILE" ]; then
      _debug "found $DOCKER_COMPOSE_FILE. building docker-compose ..."
      docker-compose -f "$DOCKER_COMPOSE_FILE" build
  elif [ -f "$DOCKER_FILE" ]; then
      _debug "found $DOCKER_FILE. building docker ..."
      if head -n1 "$DOCKER_FILE" | grep -q "dockerfile:1.0.2-experimental"; then
        export DOCKER_BUILDKIT=1
      fi
      docker build \
        --progress="$DOCKER_PROGRESS" \
        -t="$DOCKER_TAG" \
        -f="$DOCKER_FILE" \
        "$DOCKER_CONTEXT"
  else
      >&2 echo "no $DOCKER_COMPOSE_FILE or $DOCKER_FILE found"
      exit 1
  fi
}

run() {
  _debug "running ..."
  if [ -f ./docker-compose.yml ]; then
      _debug "found docker-compose file. running ..."
      # shellcheck disable=SC2046
      docker-compose -f "$DOCKER_COMPOSE_FILE" $(_envs _volumes) up
  elif [ -f ./Dockerfile ]; then
      _debug "found Dockerfile. running ..."
      _info "running docker run --rm $(_envs) $(_volumes) -ti $DOCKER_TAG"
      # shellcheck disable=SC2046
      docker run --rm $(_envs) $(_volumes) -w "$DOCKER_WORKSPACE" -ti "$DOCKER_TAG"
  else
      _error "no $DOCKER_COMPOSE_FILE or $DOCKER_FILE found"
      exit 1
  fi
}

if [ ! "${NOEXEC+x}" ]; then
  if [ "${2+x}" ]; then
    cmd="$(echo "$*" | sed -e "s/[\.\/]//g")"
    flags="$(echo "$cmd" | grep -o -e " --[^ ]*" || true)"
    flags="$(echo "$flags" | sed -e "s/ --//g")"
    if [ "$2" = "build" ]; then
      build
    elif [ "$2" = "run" ]; then
      run
    fi
    if [ "$flags" != "" ]; then
      for flag in $flags; do
        echo "flag: $flag"
        if echo "$flag" | grep -q "="; then  # flag has a value
          echo 'flag has value'
        else
          echo 'flag has no value'
        fi
      done
    fi
  else
    help
  fi
fi
