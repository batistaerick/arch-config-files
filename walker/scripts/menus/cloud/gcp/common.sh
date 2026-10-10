#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

GCP_MENUS_DIR="$CLOUD_MENUS_DIR/gcp"

gcp_cli_available() {
  command -v gcloud >/dev/null 2>&1
}

require_gcloud() {
  if ! gcp_cli_available; then
    notify-send "GCP" "gcloud CLI is not installed"
    return 1
  fi
}

# Prints the chosen project ID; returns 1 on cancel or failure.
choose_gcp_project() {
  local projects
  local chosen

  require_gcloud || return 1

  if ! projects="$(gcloud projects list --format='value(projectId)' 2>/dev/null)"; then
    notify-send "GCP" "Failed to list projects. Login or configure gcloud first."
    return 1
  fi

  if [ -z "$projects" ]; then
    notify-send "GCP" "No projects found"
    return 1
  fi

  chosen="$(printf "%s\n" "$projects" | walker_menu "GCP Project")"
  [ -n "$chosen" ] || return 1

  printf '%s\n' "$chosen"
}

back_to_gcp_menu() {
  "$GCP_MENUS_DIR/menu.sh"
}
