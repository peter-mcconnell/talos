#!/usr/bin/env sh
# help: docker build/docker-compose build
# flags:
# --tag | optional. image tag
# --push | optional. image push

set -eu


TALOS_IMAGE="${TALOS_IMAGE:-pemcconnell/talos:latest}"
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-./docker-compose.yml}"
DOCKER_TAG="${DOCKER_TAG:-${TALOS_IMAGE}}"
DOCKER_FILE="${DOCKER_FILE:-./Dockerfile}"
DOCKER_CONTEXT="${DOCKER_CONTEXT:-.}"
DOCKER_PROGRESS="${DOCKER_PROGRESS:-plain}"

# flags
FLAG_help="${FLAG_help:-}"
FLAG_tag="${FLAG_tag:-}"
FLAG_push="${FLAG_push:-False}"

main() {
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
      >&2 echo "no $DOCKER_COMPOSE_FILE or $DOCKER_FILE found"
      exit 1
  fi
}
