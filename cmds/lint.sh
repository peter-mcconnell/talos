#!/usr/bin/env sh
# help: run all available linters

set -eu


FAIL_FAST="${FAIL_FAST:-0}"

# help is the default entrypoint
help() {
    printf "\\033[36m%-20s\\033[0m %s\\n" "build" "docker build/docker-compose build"
    printf "\\033[36m%-20s\\033[0m %s\\n" "run" "docker run/docker-compose up"
}


main() {
  _heading "linting ..."
  fail=0
  # shell / bash
  _subheading "checking for shell/bash"
  shfiles="$(find . -type f -name "*.sh")"
  if [ "$shfiles" = "" ]; then
    _info "no shell/bash found. skipping"
  else
    for path in $shfiles; do
      if command -v "shellcheck" > /dev/null; then
        _shellcheck "$path" || fail=1
      else
        _warn "shell/bash found but shellcheck not installed. skipping"
        break
      fi
    done
  fi
  if [ "$FAIL_FAST" = "1" ] && [ "$fail" != "0" ]; then exit "$fail"; fi
  # dockerfile
  _subheading "checking for docker"
  dockerfiles="$(find . -type f -name "*Dockerfile")"
  if [ "$dockerfiles" = "" ]; then
    _info "no Dockerfile's found. skipping"
  else
    for path in $dockerfiles; do
      if command -v "hadolint" > /dev/null; then
        _hadolint "$path" || fail=1
      else
        _warn "shell/bash found but hadolint not installed. skipping"
        break
      fi
    done
  fi
  if [ "$FAIL_FAST" = "1" ] && [ "$fail" != "0" ]; then exit "$fail"; fi
  # python
  _subheading "checking for python"
  pyfiles="$(find . -type f -name "*.py")"
  if [ "$pyfiles" = "" ]; then
    _info "no python found. skipping"
  else
    _info "python (pylint)"
    for path in $pyfiles; do
      if command -v "pylint" > /dev/null; then
        _pylint "$path" || fail=1
      else
        _warn "python found but pylint not installed. skipping"
        break
      fi
    done
    _info "python (flake8)"
    for path in $pyfiles; do
      if command -v "pylint" > /dev/null; then
        _flake8 "$path" || fail=1
      else
        _warn "python found but flake8 not installed. skipping"
        break
      fi
    done
    _info "python (radon)"
    if find . -type f -name "*.py" | grep -q .; then
      if command -v "radon" > /dev/null; then
        _radon || fail=1
      else
        _warn "python found but radon not installed. skipping"
      fi
    fi
    _info "python (bandit)"
    if find . -type f -name "*.py" | grep -q .; then
      if command -v "bandit" > /dev/null; then
        _bandit || fail=1
      else
        _warn "python found but bandit not installed. skipping"
      fi
    fi
  fi

  exit "$fail"
}

# linters
_shellcheck() {
  _info "checking $1"
  shellcheck "$1"
}
_hadolint() {
  _info "checking $1"
  hadolint "$1"
}
_pylint() {
  _info "checking $1"
  pylint "$1"
}
_flake8() {
  _info "checking $1"
  flake8 "$1"
}
_radon() {
  radon cc .
}
_bandit() {
  bandit -r .
}


if [ "${2+x}" ]; then
  cmd="$(echo "$*" | sed -e "s/[\\.\\/]//g")"
  flags="$(echo "$cmd" | grep -o -e " --[^ ]*" || true)"
  flags="$(echo "$flags" | sed -e "s/ --//g")"
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
  main
fi
