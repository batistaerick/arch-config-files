#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/gcp/common.sh"

options="←  Back
󰊭  Login
󰅟  Check Auth
󰏗  Projects
  Compute Instances
󰉋  Storage Buckets
󰢬  Logs"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="GCP")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/cloud.sh"
    ;;
  "󰊭  Login")
    if ! gcp_cli_available; then
      notify-send "GCP" "gcloud CLI is not installed"
      exit 0
    fi
    run_in_kitty "GCP Login" "
cloud_header 'GCP login'
cloud_success 'Opening gcloud auth login...'
echo
gcloud auth login
" close-on-success
    ;;
  "󰅟  Check Auth")
    require_gcloud
    run_in_kitty "GCP Auth" "
cloud_header 'GCP auth'
gcloud auth list --format=json \
| jq -r '.[] | \"\u001b[36m\(.account)\u001b[0m  status=\(.status)\"' \
| cloud_fzf 'Accounts' plain
" close-on-success toggle
    ;;
  "󰏗  Projects")
    require_gcloud
    run_in_kitty "GCP Projects" "
cloud_header 'GCP projects'
gcloud projects list --format=json \
| jq -r '.[] | \"\u001b[36m\(.projectId)\u001b[0m  name=\(.name)  state=\(.lifecycleState)\"' \
| cloud_fzf 'Projects' plain
" close-on-success toggle
    ;;
  "  Compute Instances")
    "$GCP_MENUS_DIR/compute.sh"
    ;;
  "󰉋  Storage Buckets")
    "$GCP_MENUS_DIR/storage.sh"
    ;;
  "󰢬  Logs")
    "$GCP_MENUS_DIR/logs.sh"
    ;;
  "")
    exit 0
    ;;
esac
