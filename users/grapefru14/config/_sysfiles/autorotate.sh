#!/usr/bin/env bash
# exec >>"$HOME/.autorotate.log" 2>&1
set -euo pipefail
get_outp() {
  OUTPUT="${1:-$(niri msg outputs | grep -Po -m 1 '(?<=Output ")[^"]+')}"
}
get_outp
if [ "$OUTPUT" == "" ]; then
  echo "Waiting for output..."
  while [ "$OUTPUT" == "" ]; do
    get_outp
  done
fi
echo "Using output '$OUTPUT'"

rotate_output() {
  local orientation="$1"
  case "$orientation" in
    *normal*)    rot=normal ;;
    *right-up*)  rot=270 ;;
    *bottom-up*) rot=180 ;;
    *left-up*)   rot=90 ;;
    *) echo "Unknown orientation: $orientation" >&2; return ;;
  esac
  echo "Rotating to $rot..."
  niri msg output "$OUTPUT" transform "$rot"
}

echo "Monitoring..."
monitor-sensor | while IFS= read -r line; do
  case "$line" in
    *"Accelerometer orientation changed:"*)
      rotate_output "$line"
      ;;
    *) ;;
  esac
done
