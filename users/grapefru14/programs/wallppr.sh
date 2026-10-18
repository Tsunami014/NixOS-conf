#!/usr/bin/env bash
set -euo pipefail

WPDIR="/etc/nixos/users/grapefru14/backgrounds"
SIZE="1920x1200"
RANDOM_LABEL="[ random ]"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CUR_LINK="$HOME/Pictures/currentBg.jpg" # stable path for other tools
mkdir -p "$CACHE" "$(dirname "$CUR_LINK")"

# Don't let two invocations overlap (timer + manual change, etc.)
exec 9>"$CACHE/.lock"
flock -n 9 || exit 0

W=${SIZE%x*}; H=${SIZE#*x}
SW=$((W / 8)); SH=$((H / 8)) # blur at 1/8 scale (sigma 40 -> 5)

TRANSITIONS=(fade wipe wave grow center outer left right top bottom)

pick_random() {
  find "$WPDIR" -type f -printf "%f\n" | shuf -n 1
}

# ---- choose wallpaper ----------------------------------------------------
if [[ $# -eq 0 ]]; then
  CHOICE="$({ echo "$RANDOM_LABEL"; find "$WPDIR" -type f -printf "%f\n" | sort; } \
            | fzf --no-sort)" || exit 0
  [[ -z $CHOICE ]] && exit 0
  if [[ $CHOICE == "$RANDOM_LABEL" ]]; then NAME="$(pick_random)"; else NAME="$CHOICE"; fi
elif [[ $1 == "rand" ]]; then
  NAME="$(pick_random)"
else
  NAME="$1"
fi

NEW="$WPDIR/$NAME"
[[ -f $NEW ]] || { echo "No such wallpaper: $NEW" >&2; exit 1; }

# ---- alternate between two slots ----------------------------------------
# The new image always gets a different path than the one currently shown,
# so swww never sees "the same file changed" (the cause of the ghosting).
STATE="$CACHE/slot"
last=$(cat "$STATE" 2>/dev/null || echo 1)
slot=$(( 1 - last ))
OUT="$CACHE/bg-$slot.jpg"

# ---- render --------------------------------------------------------------
magick -define jpeg:size="${W}x${H}" "$NEW[0]" \
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
swww query >/dev/null 2>&1 || { swww-daemon >/dev/null 2>&1 & sleep 0.5; }

T="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
ANGLE=$(( RANDOM % 360 ))
POS="0.$(( RANDOM % 10 )),0.$(( RANDOM % 10 ))"

swww img "$OUT" \
  --transition-type "$T" \
  --transition-angle "$ANGLE" \
  --transition-pos "$POS" \
  --transition-duration 1.5 \
  --transition-fps 60
