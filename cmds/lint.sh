#!/usr/bin/env sh
# help: run all available linters

set -eu


FAIL_FAST="${FAIL_FAST:-0}"

main() {
  _heading "linting ..."
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
  dockerfiles="$(find "$searchpath" -type f -name "*Dockerfile")"
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
  pyfiles="$(find "$searchpath" -type f -name "*.py")"
  if [ "$pyfiles" = "" ]; then
    _info "no python found. skipping"
  else
    _info "python (pylint)"
    for path in $pyfiles; do
      if command -v "pylint" > /dev/null; then
        _pylint "$path" || fail=1
      else
        _warn "pylint not installed. skipping"
        break
      fi
    done
    _info "python (flake8)"
    for path in $pyfiles; do
      if command -v "pylint" > /dev/null; then
        _flake8 "$path" || fail=1
      else
        _warn "flake8 not installed. skipping"
        break
      fi
    done
    _info "python (radon)"
    if command -v "radon" > /dev/null; then
      _radon "$searchpath" || fail=1
    else
      _warn "radon not installed. skipping"
    fi
    _info "python (bandit)"
    if command -v "bandit" > /dev/null; then
      _bandit "$searchpath" || fail=1
    else
      _warn "bandit not installed. skipping"
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
  radon cc "$1"
}
_bandit() {
  bandit -r "$1"
}


if [ "${1+x}" ]; then
  path="."
  if [ "${2+x}" ]; then
    path="$2"
  fi
  main "$path"
fi
