#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure Resource Groups" "
cloud_header 'Azure resource groups'
cloud_kv 'Subscription' '$subscription'
echo

az group list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  location=\(.location)  state=\(.properties.provisioningState // \"N/A\")\"' \
| cloud_fzf 'Resource groups' plain
" close-on-success toggle
