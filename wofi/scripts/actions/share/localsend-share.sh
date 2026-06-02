#!/bin/bash

if (($# == 0)); then
  echo "Usage: [clipboard|file|folder]"
  exit 1
fi

MODE="$1"
shift

if [[ $MODE == "clipboard" ]]; then
  TEMP_FILE=$(mktemp --suffix=.txt)
  wl-paste >"$TEMP_FILE"
  FILES="$TEMP_FILE"
else
  if (($# > 0)); then
    FILES="$*"
  else
    if [[ $MODE == "folder" ]]; then
      # Pick a single folder from home directory
      FILES=$(find "$HOME" -type d 2>/dev/null | fzf)
    else
      # Pick one or more files from home directory
      FILES=$(find "$HOME" -type f 2>/dev/null | fzf --multi)
    fi
    [[ -z $FILES ]] && exit 0
  fi
fi

if [[ $MODE != "clipboard" ]] && echo "$FILES" | grep -q $'\n'; then
  readarray -t FILE_ARRAY <<<"$FILES"
  systemd-run --user --quiet --collect localsend --headless send "${FILE_ARRAY[@]}"
else
  systemd-run --user --quiet --collect localsend --headless send "$FILES"
fi

exit 0
