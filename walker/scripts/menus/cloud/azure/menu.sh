#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/azure/common.sh"

case "${1:-}" in
  --login)
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
    exit 0
    ;;
  --check-auth)
    require_az
    run_in_kitty "Azure Auth" "
cloud_header 'Azure auth'
az account show -o json \
| jq -r '\"\u001b[34mName:\u001b[0m \(.name)\", \"\u001b[34mID:\u001b[0m   \(.id)\", \"\u001b[34mUser:\u001b[0m \(.user.name // \"N/A\")\"'
" close-on-key toggle
    exit 0
    ;;
  --subscriptions)
    require_az
    run_in_kitty "Azure Subscriptions" "
cloud_header 'Azure subscriptions'
az account list -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  id=\(.id)  state=\(.state)\"' \
| cloud_fzf 'Subscriptions' plain
" close-on-success toggle
    exit 0
    ;;
esac

options="󰊭  Login
󰅟  Check Auth
󰏗  Subscriptions
󰉖  Resource Groups
  Virtual Machines
󰉋  Storage Accounts
󰠇  AKS Clusters
󰣇  App Services
󰈳  SQL Servers
  Container Registries
󰊕  Function Apps
󰖟  Virtual Networks
󰢬  Activity Logs"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="Azure")

case "$chosen" in
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
| jq -r '\"\u001b[34mName:\u001b[0m \(.name)\", \"\u001b[34mID:\u001b[0m   \(.id)\", \"\u001b[34mUser:\u001b[0m \(.user.name // \"N/A\")\"'
" close-on-key toggle
    ;;
  "󰏗  Subscriptions")
    require_az
    run_in_kitty "Azure Subscriptions" "
cloud_header 'Azure subscriptions'
az account list -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  id=\(.id)  state=\(.state)\"' \
| cloud_fzf 'Subscriptions' plain
" close-on-success toggle
    ;;
  "󰉖  Resource Groups")
    "$AZURE_MENUS_DIR/resource-groups.sh"
    ;;
  "  Virtual Machines")
    "$AZURE_MENUS_DIR/compute.sh"
    ;;
  "󰉋  Storage Accounts")
    "$AZURE_MENUS_DIR/storage.sh"
    ;;
  "󰠇  AKS Clusters")
    "$AZURE_MENUS_DIR/aks.sh"
    ;;
  "󰣇  App Services")
    "$AZURE_MENUS_DIR/app-service.sh"
    ;;
  "󰈳  SQL Servers")
    "$AZURE_MENUS_DIR/sql.sh"
    ;;
  "  Container Registries")
    "$AZURE_MENUS_DIR/acr.sh"
    ;;
  "󰊕  Function Apps")
    "$AZURE_MENUS_DIR/functions.sh"
    ;;
  "󰖟  Virtual Networks")
    "$AZURE_MENUS_DIR/vnet.sh"
    ;;
  "󰢬  Activity Logs")
    "$AZURE_MENUS_DIR/logs.sh"
    ;;
  "")
    exit 0
    ;;
esac
