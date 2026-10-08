#!/usr/bin/env bash
set -euo pipefail
WPDIR="/etc/nixos/users/grapefru14/backgrounds"
CUR="$HOME/Pictures/currentBg.jpg"
mkdir -p "$HOME/Pictures"
SIZE="1920x1200"
RANDOM_LABEL="[ random ]"

pick_random() {
  find "$WPDIR" -mindepth 1 -printf "%f\n" | shuf -n 1
}

if ! [[ -v 1 ]]; then
  CHOICE="$({ echo "$RANDOM_LABEL"; find "$WPDIR" -mindepth 1 -printf "%f\n" | sort; } | fzf --no-sort)"
  if [[ "$CHOICE" == "$RANDOM_LABEL" ]]; then
    NAME="$(pick_random)"
  else
    NAME="$CHOICE"
  fi
  NEW="$WPDIR/$NAME"
elif [[ "$1" == "rand" ]]; then
  NEW="$WPDIR/$(pick_random)"
else
  NEW="$WPDIR/$1"
fi

rm -f "$CUR"
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
  caelestia shell wallpaper set "$HOME/.local/state/caelestia/wallpaper/current"
fi
