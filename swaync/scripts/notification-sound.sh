#!/usr/bin/env bash

if swaync-client -D | grep -q "true"; then
  exit 0
fi

canberra-gtk-play -i message &
