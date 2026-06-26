#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure VNets" "
cloud_header 'Azure virtual networks'
cloud_kv 'Subscription' '$subscription'
echo

az network vnet list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  group=\(.resourceGroup)  location=\(.location)  prefixes=\((.addressSpace.addressPrefixes // []) | join(\",\"))\"' \
| cloud_fzf 'Virtual networks' plain
" close-on-success toggle
