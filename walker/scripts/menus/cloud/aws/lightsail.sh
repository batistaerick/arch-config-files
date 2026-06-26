#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/walker/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

options="󰍹  Instances
󰩠  Static IPs
󰖟  Distributions
  Databases"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="Lightsail - $AWS_PROFILE")

case "$chosen" in
  "󰍹  Instances")
    run_in_kitty "Lightsail Instances - $AWS_PROFILE" "
aws_header 'Lightsail instances'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) lightsail get-instances \
| jq -r '.instances[] | \"\u001b[36m\(.name)\u001b[0m  state=\(.state.name)  publicIp=\(.publicIpAddress // \"N/A\")  blueprint=\(.blueprintId)  bundle=\(.bundleId)\"' \
| aws_fzf 'Instances' plain
" close-on-success toggle
    ;;
  "󰩠  Static IPs")
    run_in_kitty "Lightsail Static IPs - $AWS_PROFILE" "
aws_header 'Lightsail static IPs'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) lightsail get-static-ips \
| jq -r '.staticIps[] | \"\u001b[36m\(.name)\u001b[0m  ip=\(.ipAddress)  attached=\(.isAttached)  resource=\(.attachedTo // \"N/A\")\"' \
| aws_fzf 'Static IPs' plain
" close-on-success toggle
    ;;
  "󰖟  Distributions")
    run_in_kitty "Lightsail Distributions - $AWS_PROFILE" "
aws_header 'Lightsail distributions'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) lightsail get-distributions \
| jq -r '.distributions[] | \"\u001b[36m\(.name)\u001b[0m  status=\(.status)  domain=\(.domainName)  enabled=\(.isEnabled)\"' \
| aws_fzf 'Distributions' plain
" close-on-success toggle
    ;;
  "  Databases")
    run_in_kitty "Lightsail Databases - $AWS_PROFILE" "
aws_header 'Lightsail databases'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) lightsail get-relational-databases \
| jq -r '.relationalDatabases[] | \"\u001b[36m\(.name)\u001b[0m  engine=\(.engine)  state=\(.state)  endpoint=\(.masterEndpoint.address // \"N/A\")\"' \
| aws_fzf 'Databases' plain
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
