#!/usr/bin/env bash

set -euo pipefail

status="$(quickshell ipc -c desktop-bar call -- notifications status)"
count="$(jq -r '.count' <<< "$status")"
dnd="$(jq -r '.doNotDisturb' <<< "$status")"
inhibited="false"

count="${count//[^0-9]/}"
[[ -n "$count" ]] || count=0

state="none"
icon="󰂜"
tooltip="No notifications"

if [[ "$dnd" == "true" && "$inhibited" == "true" ]]; then
  if ((count > 0)); then
    state="dnd-inhibited-notification"
    icon="󰂛"
    tooltip="$count Notification"
  else
    state="dnd-inhibited-none"
    icon="󰪑"
    tooltip="Do not disturb and inhibited"
  fi
elif [[ "$dnd" == "true" ]]; then
  if ((count > 0)); then
    state="dnd-notification"
    icon="󰂠"
    tooltip="$count Notification"
  else
    state="dnd-none"
    icon="󰪓"
    tooltip="Do not disturb"
  fi
elif [[ "$inhibited" == "true" ]]; then
  if ((count > 0)); then
    state="inhibited-notification"
    icon="󰂛"
    tooltip="$count Notification"
  else
    state="inhibited-none"
    icon="󰪑"
    tooltip="Notifications inhibited"
  fi
elif ((count > 0)); then
  state="notification"
  icon="󱅫"
  tooltip="$count Notification"
fi

if ((count != 1)); then
  tooltip="${tooltip/ Notification/ Notifications}"
fi

jq -cn \
  --arg text "$icon" \
  --arg tooltip "$tooltip" \
  --arg state "$state" \
  --argjson count "$count" \
  '{text:$text,tooltip:$tooltip,state:$state,count:$count,active:($count > 0)}'
