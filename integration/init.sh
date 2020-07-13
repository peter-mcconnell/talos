#!/usr/bin/env bash

arg=("$@")
for ((i = 0; i < $#; i++)); do
  echo "Executing script ./init/${arg[i]}"
  ./init/${arg[i]}
  if [ $? != 0 ]; then
    echo "Script ./init/${arg[i]} execution failed"
    exit 1
  fi
done
