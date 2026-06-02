#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure SQL" "
cloud_header 'Azure SQL servers'
cloud_kv 'Subscription' '$subscription'
echo

az sql server list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  group=\(.resourceGroup)  location=\(.location)  admin=\(.administratorLogin // \"N/A\")\"' \
| cloud_fzf 'SQL servers' plain
" close-on-success toggle
