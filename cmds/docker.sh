#!/usr/bin/env sh
# help: perform project-relevant docker commands

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
DOCKER_VOLUMES_EXT="${DOCKER_VOLUMES_EXT:-}"
PYTHONPATH="${PYTHONPATH:-.}"

# flags
FLAG_help="${FLAG_help:-}"
FLAG_tag="${FLAG_tag:-}"
FLAG_push="${FLAG_push:-False}"

# help is the default entrypoint
docker_help() {
  printf "\\033[36m%-20s\\033[0m %s\\n" "build" "docker build/docker-compose build"
  printf "\\033[36m%-20s\\033[0m %s\\n" "  --tag" "optional. image tag"
  printf "\\033[36m%-20s\\033[0m %s\\n" "  --push" "optional. push after build"
  printf "\\033[36m%-20s\\033[0m %s\\n" "run" "docker run/docker-compose up"
  printf "\\033[36m%-20s\\033[0m %s\\n" "help" "display help text"
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
DISPLAY=unix$DISPLAY
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

docker_build() {
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
    _info "built ${DOCKER_TAG}"
    if [ "$FLAG_tag" != "" ]; then
      _info "tagging ${DOCKER_TAG} as ${FLAG_tag}"
      docker tag "$DOCKER_TAG" "${FLAG_tag}"
    fi
    if [ "$FLAG_push" = "True" ]; then
      tag="$DOCKER_TAG"
      if [ "$FLAG_tag" != "" ]; then
        tag="$FLAG_tag"
      fi
      _info "pushing $tag"
      docker push "$tag"
    fi
  else
      >&2 echo "xno $DOCKER_COMPOSE_FILE or $DOCKER_FILE found"
      exit 1
  fi
}

docker_run() {
  _debug "running ..."
  cmd="$DOCKER_CMD"
  if [ "${1+x}" ]; then
    cmd="$1"
  fi
  image="$DOCKER_TAG"
  if [ "${2+x}" ]; then
    image="$2"
  fi
  if [ -f "$DOCKER_COMPOSE_FILE" ]; then
      _debug "found docker-compose file. running ..."
      # shellcheck disable=SC2046
      docker-compose -f "$DOCKER_COMPOSE_FILE" $(_envs _volumes) up
  else
    _debug "found Dockerfile. running ..."
    _debug "running docker run --rm $(_envs) $(_volumes) -w $DOCKER_WORKSPACE -ti $image $cmd"
    # shellcheck disable=SC2046,SC2086
    docker run --rm \
      $(_envs) \
      $(_volumes) \
      -w "$DOCKER_WORKSPACE" \
      -ti "$image" $cmd
  fi
}

if [ "$FLAG_help" = "True" ]; then
  test_help
  exit 0
fi
if [ ! "${NOEXEC+x}" ] && [ "${2+x}" ]; then
  if [ "$2" = "build" ]; then
    docker_build
  elif [ "$2" = "run" ]; then
    docker_run ""
  fi
fi
