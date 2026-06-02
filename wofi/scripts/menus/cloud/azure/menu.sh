#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/azure/common.sh"

options="←  Back
󰊭  Login
󰅟  Check Auth
󰏗  Subscriptions
  Virtual Machines
󰉋  Storage Accounts
󰢬  Activity Logs"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="Azure")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/cloud.sh"
    ;;
  "󰊭  Login")
    if ! azure_cli_available; then
      notify-send "Azure" "Azure CLI is not installed"
      exit 0
    fi
    run_in_kitty "Azure Login" "
cloud_header 'Azure login'
cloud_success 'Opening az login...'
echo
az login
" close-on-success
    ;;
  "󰅟  Check Auth")
    require_az
    run_in_kitty "Azure Auth" "
cloud_header 'Azure auth'
az account show -o json \
| jq -r '\"\u001b[34mName:\u001b[0m \(.name)\", \"\u001b[34mID:\u001b[0m   \(.id)\", \"\u001b[34mUser:\u001b[0m \(.user.name // \"N/A\")\"' \
| cloud_fzf 'Account'
" close-on-success
    ;;
  "󰏗  Subscriptions")
    require_az
    run_in_kitty "Azure Subscriptions" "
cloud_header 'Azure subscriptions'
az account list -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  id=\(.id)  state=\(.state)\"' \
| cloud_fzf 'Subscriptions'
" close-on-success
    ;;
  "  Virtual Machines")
    "$AZURE_MENUS_DIR/compute.sh"
    ;;
  "󰉋  Storage Accounts")
    "$AZURE_MENUS_DIR/storage.sh"
    ;;
  "󰢬  Activity Logs")
    "$AZURE_MENUS_DIR/logs.sh"
    ;;
  "")
    exit 0
    ;;
esac
