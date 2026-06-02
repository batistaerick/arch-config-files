#!/usr/bin/env bash

AWS_PROFILE="$1"
source "$HOME/.config/wofi/scripts/menus/cloud/aws/common.sh"

[ -z "$AWS_PROFILE" ] && exit 0

choose_vpc() {
  local vpcs chosen

  if ! vpcs="$(aws_cli ec2 describe-vpcs | jq -r '.Vpcs[] | "\((.Tags // [] | map(select(.Key == \"Name\"))[0].Value) // \"<no-name>\")  \(.VpcId)"')"; then
    notify-send "VPC" "Failed to list VPCs"
    exit 1
  fi

  [ -z "$vpcs" ] && notify-send "VPC" "No VPCs found" && exit 0
  chosen="$(printf "%s\n" "$vpcs" | wofi_menu "VPC")"
  [ -z "$chosen" ] && exit 0
  echo "$chosen" | awk '{ print $NF }'
}

options="←  Back
󰩠  VPCs
󰩠  Subnets
󰑓  Route tables
󰒋  Network ACLs
󰒄  VPC endpoints"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="VPC - $AWS_PROFILE")

case "$chosen" in
  "←  Back")
    back_to_aws_menu
    ;;
  "󰩠  VPCs")
    run_in_kitty "VPCs - $AWS_PROFILE" "
aws_header 'VPCs'
aws_kv 'Profile' '$AWS_PROFILE'
echo

$(aws_base) ec2 describe-vpcs \
| jq -r '.Vpcs[] | \"\u001b[36m\((.Tags // [] | map(select(.Key == \"Name\"))[0].Value) // \"<no-name>\")\u001b[0m  id=\(.VpcId)  cidr=\(.CidrBlock)  default=\(.IsDefault)  state=\(.State)\"' \
| aws_fzf 'VPCs' plain
" close-on-success toggle
    ;;
  "󰩠  Subnets")
    vpc_id="$(choose_vpc)"
    quoted_vpc_id="$(shell_quote "$vpc_id")"

    run_in_kitty "Subnets - $AWS_PROFILE" "
aws_header 'VPC subnets'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'VPC' $quoted_vpc_id
echo

$(aws_base) ec2 describe-subnets --filters Name=vpc-id,Values=$quoted_vpc_id \
| jq -r '.Subnets[] | \"\u001b[36m\((.Tags // [] | map(select(.Key == \"Name\"))[0].Value) // \"<no-name>\")\u001b[0m  id=\(.SubnetId)  cidr=\(.CidrBlock)  az=\(.AvailabilityZone)  availableIps=\(.AvailableIpAddressCount)\"' \
| aws_fzf 'Subnets' plain
" close-on-success toggle
    ;;
  "󰑓  Route tables")
    vpc_id="$(choose_vpc)"
    quoted_vpc_id="$(shell_quote "$vpc_id")"

    run_in_kitty "Route Tables - $AWS_PROFILE" "
aws_header 'VPC route tables'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'VPC' $quoted_vpc_id
echo

$(aws_base) ec2 describe-route-tables --filters Name=vpc-id,Values=$quoted_vpc_id \
| jq -r '.RouteTables[] | \"\u001b[36m\(.RouteTableId)\u001b[0m  routes=\(.Routes | length)  associations=\(.Associations | length)\"' \
| aws_fzf 'Route tables' plain
" close-on-success toggle
    ;;
  "󰒋  Network ACLs")
    vpc_id="$(choose_vpc)"
    quoted_vpc_id="$(shell_quote "$vpc_id")"

    run_in_kitty "Network ACLs - $AWS_PROFILE" "
aws_header 'VPC network ACLs'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'VPC' $quoted_vpc_id
echo

$(aws_base) ec2 describe-network-acls --filters Name=vpc-id,Values=$quoted_vpc_id \
| jq -r '.NetworkAcls[] | \"\u001b[36m\(.NetworkAclId)\u001b[0m  default=\(.IsDefault)  entries=\(.Entries | length)  associations=\(.Associations | length)\"' \
| aws_fzf 'Network ACLs' plain
" close-on-success toggle
    ;;
  "󰒄  VPC endpoints")
    vpc_id="$(choose_vpc)"
    quoted_vpc_id="$(shell_quote "$vpc_id")"

    run_in_kitty "VPC Endpoints - $AWS_PROFILE" "
aws_header 'VPC endpoints'
aws_kv 'Profile' '$AWS_PROFILE'
aws_kv 'VPC' $quoted_vpc_id
echo

$(aws_base) ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$quoted_vpc_id \
| jq -r '.VpcEndpoints[] | \"\u001b[36m\(.VpcEndpointId)\u001b[0m  service=\(.ServiceName)  type=\(.VpcEndpointType)  state=\(.State)\"' \
| aws_fzf 'VPC endpoints' plain
" close-on-success toggle
    ;;
  "")
    exit 0
    ;;
esac
