#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
  pkill -x hypridle
else
  if command -v uwsm >/dev/null 2>&1; then
    uwsm app -- hypridle >/dev/null 2>&1 &
  else
    setsid hypridle >/dev/null 2>&1 &
  fi

fi
