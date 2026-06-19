#!/usr/bin/env bash

query="$(
  wofi \
    --dmenu \
    --exec-search \
    --hide-scroll \
    --cache-file /dev/null \
    --height 82 \
    --prompt="Google it..." \
    < /dev/null
)"

query="${query#"${query%%[![:space:]]*}"}"
query="${query%"${query##*[![:space:]]}"}"

[[ -z "$query" ]] && exit 0

encoded_query="$(printf '%s' "$query" | jq -sRr @uri)"

xdg-open "https://www.google.com/search?q=$encoded_query"
