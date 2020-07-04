#!/usr/bin/env sh
# help: run all available testers

set -eu


BATS_CMD="${BATS_CMD:-bats .}"
PYTEST_CMD="${PYTEST_CMD:-pytest .}"
FAIL_FAST="${FAIL_FAST:-0}"

# flags
FLAG_help="${FLAG_help:-False}"
FLAG_pipenv="${FLAG_pipenv:-False}"
FLAG_pipenvdev="${FLAG_pipenvdev:-False}"

test_help() {
  printf "\\033[36m%-20s\\033[0m %s\\n" "talos test" ""
  printf "\\033[36m%-20s\\033[0m %s\\n" "  --pipenv" "optional. wrap tests in pipenv"
  printf "\\033[36m%-20s\\033[0m %s\\n" "  --pipenvdev" "optional. wrap tests in pipenv (using pipenv install --dev)"
  printf "\\033[36m%-20s\\033[0m %s\\n" "help" "display help text"
}

main() {
  _heading "testing ..."
  searchpath="."
  if [ "${1+x}" ]; then
    searchpath="$1"
  fi
  fail=0
  # shell / bash
  _subheading "checking for shell/bash"
  shfiles="$(find "$searchpath" -type f -name "*.sh")"
  if [ "$shfiles" = "" ]; then
    _info "no shell/bash found. skipping"
  else
    for path in $shfiles; do
      if command -v "bats" > /dev/null; then
        _bats "$path" || fail=1
      else
        _warn "shell/bash found but BATS not installed. skipping"
        break
      fi
    done
  fi
  if [ "$FAIL_FAST" = "1" ] && [ "$fail" != "0" ]; then exit "$fail"; fi
  # python
  _subheading "checking for python"
  pyfiles="$(find "$searchpath" -type f -name "*.py")"
  if [ "$pyfiles" = "" ]; then
    _info "no python found. skipping"
  else
    _info "python (pytest)"
    if command -v "pytest" > /dev/null; then
      _pytest || fail=1
    else
      _warn "pytest not installed. skipping"
    fi
  fi

  exit "$fail"
}

# testers
_bats() {
  _info "running $BATS_CMD"
  eval "$BATS_CMD"
}
_pytest() {
  _info "running $PYTEST_CMD"
  if [ "$FLAG_pipenv" = "True" ] || [ "$FLAG_pipenvdev" = "True" ]; then
    if ! command -v "pipenv" > /dev/null; then
      _error "'pipenv' not found!"
      exit 1
    fi
    if [ "$FLAG_pipenvdev" = "True" ]; then
      pipenv install --dev
    else
      pipenv install
    fi
    _info "running $PYTEST_CMD in pipenv"
    pipenv run "$PYTEST_CMD"
  else
    _info "running $PYTEST_CMD"
    eval "$PYTEST_CMD"
  fi
}


if [ "$FLAG_help" = "True" ]; then
  test_help
  exit 0
fi
if [ "${1+x}" ]; then
  path="."
  if [ "${2+x}" ] && ! echo "$2" | grep -q "^--"; then
    if [ -e "$2" ]; then
      path="$2"
    else
      _error "'$2' not found"
      exit 1
    fi
  fi
  main "$path"
fi
