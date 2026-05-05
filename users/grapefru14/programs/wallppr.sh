#!/usr/bin/env bash
set -euo pipefail
WPDIR="$HOME/Pictures/backgrounds"
CUR="$HOME/Pictures/currentBg.jpg"
if ! [[ -v 1 ]]; then
  NEW="$WPDIR/$(find "$WPDIR" -mindepth 1 -printf "%f\n" | sort | fzf --no-sort)"
elif [[ "$1" == "rand" ]]; then
  NEW="$WPDIR/$(find "$WPDIR" -mindepth 1 -printf "%f\0" | shuf -z -n 1)"
else
  NEW="$WPDIR/$1"
fi
ln -f "$NEW" "$CUR"
swww img "$CUR" --resize fit --transition-type fade --transition-duration 0.2
