#!/bin/bash

if pgrep -x waybar >/dev/null; then
  pkill -x waybar
else
  ~/.config/waybar/scripts/start-profiled-waybar.sh >/dev/null 2>&1 &
fi
