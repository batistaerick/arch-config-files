#!/usr/bin/env bash

players=$(playerctl -l 2>/dev/null)

if [[ -n "$players" ]]; then
  status=$(playerctl status 2>/dev/null)

  if [[ "$status" == "Playing" ]]; then
    echo "⏮  ⏸  ⏭"
  else
    echo "⏮  ▶  ⏭"
  fi
else
  echo ""
fi
