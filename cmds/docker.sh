#!/usr/bin/env sh
# help: perform project-relevant docker commands

main(){
  if [ "x${TALOS_DIR}" != "x" ]; then
    "${TALOS_DIR}/talos.sh" docker --help
    exit 0
  fi
  talos docker --help
}
