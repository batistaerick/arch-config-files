#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure VMs" "
cloud_header 'Azure virtual machines'
cloud_kv 'Subscription' '$subscription'
echo

az vm list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  group=\(.resourceGroup)  location=\(.location)  size=\(.hardwareProfile.vmSize // \"N/A\")\"' \
| cloud_fzf 'VMs' plain
" close-on-success toggle
