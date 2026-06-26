#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure App Services" "
cloud_header 'Azure App Services'
cloud_kv 'Subscription' '$subscription'
echo

az webapp list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  group=\(.resourceGroup)  location=\(.location)  state=\(.state // \"N/A\")  host=\((.defaultHostName // \"N/A\"))\"' \
| cloud_fzf 'App Services' plain
" close-on-success toggle
