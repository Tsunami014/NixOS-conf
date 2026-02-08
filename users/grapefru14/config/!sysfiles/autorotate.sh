#!/usr/bin/env bash
set -euo pipefail
OUTPUT="${1:-$(niri msg outputs | grep -Po -m 1 '(?<=Output ")[^"]+')}"
[ -n "$OUTPUT" ] || { echo "No output found; run this inside niri session."; exit 1; }

rotate_output() {
  local orientation="$1"
  case "$orientation" in
    *normal*)    niri msg output "$OUTPUT" transform normal ;;
    *right-up*)  niri msg output "$OUTPUT" transform 270 ;;
    *bottom-up*) niri msg output "$OUTPUT" transform 180 ;;
    *left-up*)   niri msg output "$OUTPUT" transform 90 ;;
    *) echo "Unknown orientation: $orientation" >&2 ;;
  esac
}

monitor-sensor | while IFS= read -r line; do
  case "$line" in
    *"Accelerometer orientation changed:"*)
      rotate_output "$line"
      ;;
    *) ;;
  esac
done
