#!/usr/bin/env bash
set -euo pipefail

WPDIR="/etc/nixos/users/grapefru14/backgrounds"
SIZE="1920x1200"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CUR_LINK="$HOME/Pictures/currentBg.jpg" # stable path for other tools
mkdir -p "$CACHE" "$(dirname "$CUR_LINK")"

exec 9>"$CACHE/.lock" # Lock here

W=${SIZE%x*}; H=${SIZE#*x}
SW=$((W / 8)); SH=$((H / 8)) # blur at 1/8 scale (sigma 40 -> 5)

TRANSITIONS=(fade wipe wave grow center outer left right top bottom)

pick_random() {
  find "$WPDIR" -mindepth 2 -maxdepth 2 -type f | shuf -n 1
}

# ---- choose wallpaper ----------------------------------------------------
if [[ $# -eq 0 ]]; then
  export WPDIR
  # shellcheck disable=SC2016  # preview is intentionally expanded by fzf's shell
  CHOICE="$(
    find "$WPDIR" -mindepth 2 -maxdepth 2 -type f -printf '%f\t%P\n' | sort |
      fzf --no-sort --delimiter=$'\t' --with-nth=1 \
        --multi \
        --prompt='wallpaper> ' \
        --header=$'Tab: random from multiple options\nCtrl-R: random from all results' \
        --bind 'ctrl-r:select-all+accept' \
        --preview='chafa -f symbols --colors full --animate off \
          -s "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" "$WPDIR/"{2}' \
        --preview-window=right:60% |
      cut -f2
  )" || exit 0
  [[ -z $CHOICE ]] && exit 0

  # One line = that file; several lines = random among them
  NEW="$WPDIR/$(shuf -n 1 <<<"$CHOICE")"
elif [[ $1 == "rand" ]]; then
  NEW="$(pick_random)"
else
  # Allow a relative path, bare filename or absolute path
  if [[ $1 == /* ]]; then
    NEW="$1"
  elif [[ -f $WPDIR/$1 ]]; then
    NEW="$WPDIR/$1"
  else
    # Bare filename: look for it one level down
    NEW="$(find "$WPDIR" -mindepth 2 -maxdepth 2 -type f -name "$(basename "$1")" | head -n 1)"
  fi
fi

[[ -f $NEW ]] || { echo "No such wallpaper: $NEW" >&2; exit 1; }

flock -w 10 9 || { echo "Another wallpaper change is in progress" >&2; exit 1; }

# ---- alternate between two slots ----------------------------------------
# The new image always gets a different path than the one currently shown,
# so swww never sees "the same file changed" (the cause of the ghosting).
STATE="$CACHE/slot"
last=$(cat "$STATE" 2>/dev/null || echo 1)
slot=$(( 1 - last ))
OUT="$CACHE/bg-$slot.jpg"

# ---- render --------------------------------------------------------------
magick -define jpeg:size="${W}x${H}" "${NEW[0]}" \
  -background grey -alpha remove -alpha off \
  -write mpr:src +delete \
  \( mpr:src -resize "${SW}x${SH}^" -gravity center -extent "${SW}x${SH}" \
     -blur 0x5 -resize "${SIZE}!" \) \
  \( mpr:src -resize "$SIZE" \) \
  -gravity center -composite \
  -quality 95 "$OUT"

echo "$slot" > "$STATE"
ln -sfn "$OUT" "$CUR_LINK"

# ---- apply with a random transition --------------------------------------
swww query >/dev/null 2>&1 || { swww-daemon 9>&- >/dev/null 2>&1 & sleep 0.5; }

T="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
ANGLE=$(( RANDOM % 360 ))
POS="0.$(( RANDOM % 10 )),0.$(( RANDOM % 10 ))"

swww img "$OUT" \
  --transition-type "$T" \
  --transition-angle "$ANGLE" \
  --transition-pos "$POS" \
  --transition-duration 1.5 \
  --transition-fps 60

upd-theme
