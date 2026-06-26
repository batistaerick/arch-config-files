#!/usr/bin/env bash
set -euo pipefail

workspace="${1:?workspace number required}"

active_workspace_json="$(hyprctl -j activeworkspace 2>/dev/null || printf '{}')"
workspaces="$(hyprctl -j workspaces 2>/dev/null || printf '[]')"
monitors="$(hyprctl -j monitors 2>/dev/null || printf '[]')"

active_workspace="$(jq -r '.id // empty' <<<"$active_workspace_json")"

classes=()
tooltip="Workspace ${workspace}"

if [ "$active_workspace" = "$workspace" ]; then
  classes+=("active")
fi

if jq -e --argjson workspace "$workspace" 'any(.[]; .activeWorkspace.id == $workspace)' >/dev/null <<<"$monitors"; then
  classes+=("visible")
fi

workspace_info="$(jq -c --argjson workspace "$workspace" '.[] | select(.id == $workspace)' <<<"$workspaces" | head -n 1)"
if [ -n "$workspace_info" ]; then
  classes+=("occupied")
  monitor="$(jq -r '.monitor // empty' <<<"$workspace_info")"
  windows="$(jq -r '.windows // 0' <<<"$workspace_info")"
  tooltip="Workspace ${workspace}"
  if [ -n "$monitor" ]; then
    tooltip="${tooltip} on ${monitor}"
  fi
  tooltip="${tooltip} (${windows} windows)"
else
  classes+=("empty")
fi

jq -cn \
  --arg text "$workspace" \
  --arg tooltip "$tooltip" \
  --argjson class "$(printf '%s\n' "${classes[@]}" | jq -R . | jq -s .)" \
  '{text: $text, tooltip: $tooltip, class: $class}'
