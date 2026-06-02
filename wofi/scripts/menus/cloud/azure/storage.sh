#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure Storage" "
cloud_header 'Azure storage accounts'
cloud_kv 'Subscription' '$subscription'
echo

az storage account list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  group=\(.resourceGroup)  location=\(.location)  sku=\(.sku.name)\"' \
| cloud_fzf 'Storage' plain
" close-on-success toggle
