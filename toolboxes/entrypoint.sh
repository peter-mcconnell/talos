#!/usr/bin/env sh
# shellcheck disable=SC2230,SC2086

set -e

# -e USER=... set. create them to avoid "no matching entries in passwd" error
user="$(whoami)"
if [ "${USER+x}" ]; then
  extargs=
  user="$USER"
  if [ "${USER_ID+x}" ]; then
    extargs="$extargs -u $USER_ID"
  fi
  useradd $extargs "$USER" > /dev/null
  if grep -q -e "^docker:" < /etc/group; then
    usermod -aG docker "$USER"
  fi
  echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  if [ -f /etc/sudoers ]; then
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  fi
fi

su "$user" -c -- "$(echo "$*" | sed -e "s/^sh -c //" -e "s/^bash -c //")"
