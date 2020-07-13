#!/usr/bin/env sh

set -e

help() {
  path="$0"
  cmd=""
  if [ "${1+x}" ]; then
    path="$1"
  fi
  if [ "${2+x}" ]; then
    cmd="$2"
  fi

  color="\\033[36m"
  if [ "$NOCOLOR" = "True" ]; then
    color=""
  fi
  # get the arguments section
  prefix="talos"
  if [ "$cmd" != "" ]; then
    prefix="$prefix $cmd"
  fi
  echo "${color}${prefix}\\e[0m"
  printf "$color%-20s\\033[0m %s\\n" \
    "  --help" \
    "get all available help options"
  recording="0"
  if grep -q "^# flags:" < "$path"; then
    while read -r line; do
      if [ "$recording" = "1" ]; then
        if ! echo "$line" | grep -q "^# --"; then
          break
        fi
        printf "$color%-20s\\033[0m %s\\n" \
          "  $(echo "$line" | sed -e "s/^# \\([^ ]*\\).*$/\\1/")" \
          "$(echo "$line" | sed -e "s/^.* | \\(.*\\)$/\\1/")"
      elif echo "$line" | grep -q "^# flags:"; then
        recording="1"
      fi
    done < "$path"
  fi

  # subcommands
  dir="$SRC_DIR"
  if [ "$cmd" != "" ]; then
    dir="$(echo "$path" | sed -e "s/^\\(.*\\/\\)[^\\/]*$/\\1/")"
  fi
  if [ "$cmd" != "" ]; then
    if [ -d "${dir}$(echo "$cmd" | tr ' ' '/')" ]; then
      dir="${dir}$(echo "$cmd" | tr ' ' '/')"
    else
      return 0  # no sub-commands for the $cmd
    fi
  fi
  cmddirs="${PROJECT_ROOT}.talos/cmds/ $dir"
  cmdcache=""
  for cmddir in $cmddirs; do
    if [ -d "$cmddir" ]; then
      # shellcheck disable=SC2044
      for file in $(find "$cmddir" -maxdepth 1 -type f -name "*.sh"); do
        name="$(echo "$file" | sed -e "s/^.*\\/\\([^\\/]*\\).sh$/\\1/")"
        if echo "$cmdcache" | grep -q "@$name@"; then
          _debug "command already found. first come first served. skipping"
          continue
        fi
        cmdcache="${cmdcache}@$name@"
        desc="$(head -n 10 "$file" | grep "# help: " | sed -e "s/^.*help: //")"
        printf "$color%-20s\\033[0m %s\\n" "$prefix $name" "$desc"
      done
    fi
  done
}
