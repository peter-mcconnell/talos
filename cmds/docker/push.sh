#!/usr/bin/env sh
# help: docker push
# flags:
# --tag | optional. image tag

set -eu


DOCKER_TAG="${DOCKER_TAG:-}"

# flags
FLAG_help="${FLAG_help:-}"
FLAG_tag="${FLAG_tag:-}"

main() {
  tag="$DOCKER_TAG"
  if [ "$FLAG_tag" != "" ]; then
    tag="$FLAG_tag"
  fi
  _info "pushing to $tag"
  docker push "$tag"
}
