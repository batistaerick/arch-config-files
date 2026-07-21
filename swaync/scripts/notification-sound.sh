#!/usr/bin/env bash

~/.config/swaync/scripts/notification-log.sh

if swaync-client -D | grep -q "true"; then
  exit 0
fi

canberra-gtk-play -i message &
