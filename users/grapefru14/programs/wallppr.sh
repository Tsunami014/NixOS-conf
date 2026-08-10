#!/usr/bin/env bash
set -euo pipefail
WPDIR="/etc/nixos/users/grapefru14/backgrounds"
CUR="$HOME/Pictures/currentBg.jpg"
SIZE="1920x1200"
if ! [[ -v 1 ]]; then
  NEW="$WPDIR/$(find "$WPDIR" -mindepth 1 -printf "%f\n" | sort | fzf --no-sort)"
elif [[ "$1" == "rand" ]]; then
  NEW="$WPDIR/$(find "$WPDIR" -mindepth 1 -printf "%f\0" | shuf -z -n 1)"
else
  NEW="$WPDIR/$1"
fi

rm "$CUR" 2&>/dev/null || true
magick "$NEW" \
  -background grey -alpha remove -alpha off \
  \( -clone 0 -resize "$SIZE^" -gravity center -extent "$SIZE" -blur 0x40 \) \
  \( -clone 0 -resize "$SIZE" -gravity center \) \
  -delete 0 -gravity center -composite -layers merge "$CUR"

if [ -n "${NIRI_SOCKET:-}" ]; then
  swww clear-cache
  swww img "$CUR" --transition-type none
else
  caelestia wallpaper -f "$CUR"
fi
