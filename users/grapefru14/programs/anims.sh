#!/usr/bin/env bash
set -euo pipefail

# Find shaders at https://github.com/liixini/shaders
ANIMDIR="$HOME/.config/niri/anims"
RANDOM_LABEL="[ random ]"

pick_random() {
  find "$ANIMDIR" -type f -printf "%f\n" | shuf -n 1
}

if [[ $# -eq 0 ]]; then
  CHOICE="$({ echo "$RANDOM_LABEL"; find "$ANIMDIR" -type f -printf "%f\n" | sort; } \
            | fzf --no-sort)" || exit 0
  [[ -z $CHOICE ]] && exit 0
  if [[ $CHOICE == "$RANDOM_LABEL" ]]; then NAME="$(pick_random)"; else NAME="$CHOICE"; fi
elif [[ $1 == "rand" ]]; then
  NAME="$(pick_random)"
else
  NAME="$1.kdl"
fi

NEW="$ANIMDIR/$NAME"
[[ -f $NEW ]] || { echo "No such animation: $NEW" >&2; exit 1; }

mkdir -p "$HOME/.niriextra"
cp "$NEW" "$HOME/.niriextra/animations.kdl"
