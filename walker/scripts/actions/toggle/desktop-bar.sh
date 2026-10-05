#!/usr/bin/env bash

set -euo pipefail

if quickshell list --all 2>/dev/null | grep -q 'Config path: .*/quickshell/desktop-bar/shell.qml'; then
  quickshell kill -c desktop-bar >/dev/null 2>&1 || true
else
  quickshell -c desktop-bar --daemonize
fi
