#!/usr/bin/env bash

query="$(
  printf "\n" |
    wofi --dmenu --cache-file /dev/null --height 100 --prompt="Google it..."
)"

[[ -z "$query" ]] && exit 0

encoded_query="$(printf '%s' "$query" | jq -sRr @uri)"

xdg-open "https://www.google.com/search?q=$encoded_query"
