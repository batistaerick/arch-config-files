#!/usr/bin/env bash
set -euo pipefail

log_file="/tmp/swaync-notifications.log"

{
  printf '\n--- %s ---\n' "$(date --iso-8601=seconds)"
  printf 'pid=%s\n' "$$"
  env | sort | sed -n '/^SWAYNC_/p;/^NOTIFICATION_/p;/^APP/p;/^SUMMARY/p;/^BODY/p;/^URGENCY/p;/^CATEGORY/p'
} >>"$log_file" 2>&1

