#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

choose_distribution() {
  local distributions chosen

  if ! distributions="$(aws_cli cloudfront list-distributions | jq -r '.DistributionList.Items[]? | "\(.DomainName)  \(.Id)"')"; then
    notify-send "CloudFront" "Failed to list distributions"
    exit 1
  fi

  [ -z "$distributions" ] && notify-send "CloudFront" "No distributions found" && exit 0
  chosen="$(printf "%s\n" "$distributions" | wofi_menu "Distribution")"
  [ -z "$chosen" ] && exit 0
  echo "$chosen" | awk '{ print $NF }'
}

options="←  Back
󰖟  Distributions
󰅟  Distribution details
󰑓  Invalidations"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="CloudFront - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰖟  Distributions")
    run_in_kitty "CloudFront Distributions - $AWS_PROFILE" "
aws_header 'CloudFront distributions'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) cloudfront list-distributions \
| jq -r '.DistributionList.Items[]? | \"\u001b[36m\(.DomainName)\u001b[0m  id=\(.Id)  status=\(.Status)  enabled=\(.Enabled)  aliases=\([.Aliases.Items[]?] | join(\",\"))\"' \
| aws_fzf 'Distributions' plain
" close-on-success toggle
    ;;
  "󰅟  Distribution details")
    distribution_id="$(choose_distribution)"
    quoted_distribution_id="$(shell_quote "$distribution_id")"

    run_in_kitty "CloudFront Distribution - $AWS_PROFILE" "
aws_header 'CloudFront distribution'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Distribution' $quoted_distribution_id
echo

$(aws_base) cloudfront get-distribution --id $quoted_distribution_id | aws_json
" close-on-success toggle
    ;;
  "󰑓  Invalidations")
    distribution_id="$(choose_distribution)"
    quoted_distribution_id="$(shell_quote "$distribution_id")"

    run_in_kitty "CloudFront Invalidations - $AWS_PROFILE" "
aws_header 'CloudFront invalidations'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'Distribution' $quoted_distribution_id
echo

$(aws_base) cloudfront list-invalidations --distribution-id $quoted_distribution_id \
| jq -r '.InvalidationList.Items[]? | \"\u001b[36m\(.Id)\u001b[0m  status=\(.Status)  created=\(.CreateTime)\"' \
| aws_fzf 'Invalidations' plain
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
