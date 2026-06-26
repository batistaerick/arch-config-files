#!/usr/bin/env bash

source "$HOME/.config/walker/scripts/menus/cloud/azure/common.sh"

subscription="$(choose_azure_subscription)"

run_in_kitty "Azure AKS" "
cloud_header 'Azure AKS clusters'
cloud_kv 'Subscription' '$subscription'
echo

az aks list --subscription '$subscription' -o json \
| jq -r '.[] | \"\u001b[36m\(.name)\u001b[0m  group=\(.resourceGroup)  location=\(.location)  version=\(.kubernetesVersion)  state=\(.powerState.code // \"N/A\")\"' \
| cloud_fzf 'AKS clusters' plain
" close-on-success toggle
