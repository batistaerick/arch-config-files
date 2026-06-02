#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

choose_hosted_zone() {
  local zones chosen

  if ! zones="$(aws_cli route53 list-hosted-zones | jq -r '.HostedZones[] | "\(.Name)  \(.Id | split("/")[-1])"')"; then
    notify-send "Route 53" "Failed to list hosted zones"
    exit 1
  fi

  [ -z "$zones" ] && notify-send "Route 53" "No hosted zones found" && exit 0
  chosen="$(printf "%s\n" "$zones" | wofi_menu "Hosted Zone")"
  [ -z "$chosen" ] && exit 0
  echo "$chosen" | awk '{ print $NF }'
}

options="←  Back
󰖟  Hosted zones
󰑓  Records
󰅟  Zone details"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="Route 53 - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰖟  Hosted zones")
    run_in_kitty "Route 53 Zones - $AWS_PROFILE" "
aws_header 'Route 53 hosted zones'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) route53 list-hosted-zones \
| jq -r '.HostedZones[] | \"\u001b[36m\(.Name)\u001b[0m  id=\(.Id | split(\"/\")[-1])  records=\(.ResourceRecordSetCount)  private=\(.Config.PrivateZone)\"' \
| aws_fzf 'Hosted zones' plain
" close-on-success toggle
    ;;
  "󰑓  Records")
    zone_id="$(choose_hosted_zone)"
    quoted_zone_id="$(shell_quote "$zone_id")"

    run_in_kitty "Route 53 Records - $AWS_PROFILE" "
aws_header 'Route 53 records'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Zone' $quoted_zone_id
echo

$(aws_base) route53 list-resource-record-sets --hosted-zone-id $quoted_zone_id \
| jq -r '.ResourceRecordSets[] | \"\u001b[36m\(.Name)\u001b[0m  type=\(.Type)  ttl=\(.TTL // \"alias\")  values=\([.ResourceRecords[]?.Value] | join(\",\")) alias=\(.AliasTarget.DNSName // \"\")\"' \
| aws_fzf 'Records' plain
" close-on-success toggle
    ;;
  "󰅟  Zone details")
    zone_id="$(choose_hosted_zone)"
    quoted_zone_id="$(shell_quote "$zone_id")"

    run_in_kitty "Route 53 Zone - $AWS_PROFILE" "
aws_header 'Route 53 hosted zone'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Zone' $quoted_zone_id
echo

$(aws_base) route53 get-hosted-zone --id $quoted_zone_id | aws_json
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
