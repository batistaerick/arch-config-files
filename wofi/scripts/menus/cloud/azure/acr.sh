#!/usr/bin/env bash

source "$HOME/.config/wofi/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure ACR" "
cloud_header 'Azure Container Registries'
cloud_kv 'Subscription' '$subscription'
echo

az acr list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  group=\(.resourceGroup)  location=\(.location)  sku=\(.sku.name // \"N/A\")  login=\(.loginServer // \"N/A\")\"' \
| cloud_fzf 'Registries' plain
" close-on-success toggle
