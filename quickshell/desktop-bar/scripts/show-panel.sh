#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  wifi|bluetooth|volume|mic|keyboard|calendar|weather|hardware|ai|notifications) ;;
  *) exit 2 ;;
esac
sleep 0.2
exec quickshell ipc -c desktop-bar call -- panels show "$1"
