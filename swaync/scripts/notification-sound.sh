#!/usr/bin/env bash

~/.config/swaync/scripts/notification-log.sh >/dev/null 2>&1

if swaync-client -D | grep -q "true"; then
  exit 0
fi

canberra-gtk-play -i message >/dev/null 2>&1 &
