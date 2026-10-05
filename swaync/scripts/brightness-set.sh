#!/usr/bin/env bash
exec python3 "$(dirname "$0")/brightness-control.py" set "${1:-}"
