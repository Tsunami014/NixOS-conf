#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "$0")"

WPDIR="/etc/nixos/users/grapefru14/backgrounds"
SIZE="1920x1200"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CUR_LINK="$HOME/Pictures/currentBg.jpg" # stable path for other tools
mkdir -p "$CACHE" "$(dirname "$CUR_LINK")"

exec 9>"$CACHE/.lock" # Lock here

W=${SIZE%x*}; H=${SIZE#*x}
SW=$((W / 8)); SH=$((H / 8)) # blur at 1/8 scale

TRANSITIONS=(fade wipe wave grow center outer left right top bottom)

HEADER=$(cat <<EOF
Tab: random from multiple options
Ctrl-R: random from all results
Alt-H: toggle hidden
EOF
)

list_wallpapers() { # Excluding hidden
  find "$WPDIR" -mindepth 2 -maxdepth 2 -type f ! -path "$WPDIR/.*" "$@"
}
list_all_wallpapers() { # Including hidden
  find "$WPDIR" -mindepth 2 -maxdepth 2 -type f "$@"
}

pick_random() {
  list_wallpapers | shuf -n 1
}


# Fzf internal commands
if [[ ${1:-} == __list ]]; then
  if [[ ${2:-} == all ]]; then
    list_all_wallpapers -printf '%f\t%P\n'
  else
    list_wallpapers -printf '%f\t%P\n'
  fi | sort
  exit 0
fi

if [[ ${1:-} == __toggle ]]; then
  if [[ "$(cat "$2" 2>/dev/null)" == all ]]; then
    echo vis >"$2"
    echo "reload('$SELF' __list vis)+change-prompt(wallpaper> )"
  else
    echo all >"$2"
    echo "reload('$SELF' __list all)+change-prompt(wallpaper [hidden]> )"
  fi
  exit 0
fi

# Choose wallpaper
if [[ $# -eq 0 ]]; then
  export WPDIR
  MODE="$CACHE/fzf-mode"
  echo vis >"$MODE"

  # shellcheck disable=SC2016
  CHOICE="$(
    "$SELF" __list vis |
      fzf --no-sort --delimiter=$'\t' --with-nth=1 \
        --multi \
        --prompt='wallpaper> ' \
        --header="$HEADER" \
        --bind 'ctrl-r:select-all+accept' \
        --bind "alt-h:transform:'$SELF' __toggle '$MODE'" \
        --preview='chafa -f symbols --colors full --animate off \
          -s "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" "$WPDIR/"{2}' \
        --preview-window=right:60% |
      cut -f2
  )" || exit 0
  [[ -z $CHOICE ]] && exit 0

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
    NEW="$(list_all_wallpapers -name "$(basename "$1")" | head -n 1)"
  fi
fi

[[ -f $NEW ]] || { echo "No such wallpaper: $NEW" >&2; exit 1; }

flock -w 10 9 || { echo "Another wallpaper change is in progress" >&2; exit 1; }

# Alternate between two slots
# The new image always gets a different path than the one currently shown,
# so awww never sees "the same file changed" (the cause of the ghosting).
STATE="$CACHE/slot"
last=$(cat "$STATE" 2>/dev/null || echo 1)
slot=$(( 1 - last ))
OUT="$CACHE/bg-$slot.jpg"

# Render
magick -define jpeg:size="${W}x${H}" "$NEW" \
  -background grey -alpha remove -alpha off \
  -write mpr:src +delete \
  \( mpr:src -resize "${SW}x${SH}^" -gravity center -extent "${SW}x${SH}" \
     -blur 0x5 -resize "${SIZE}!" \) \
  \( mpr:src -resize "$SIZE" \) \
  -gravity center -composite \
  -quality 95 "$OUT"

echo "$slot" > "$STATE"
ln -sfn "$OUT" "$CUR_LINK"

# Apply with a random transition
awww query >/dev/null 2>&1 || { awww-daemon 9>&- >/dev/null 2>&1 & sleep 0.5; }

T="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
ANGLE=$(( RANDOM % 360 ))
POS="0.$(( RANDOM % 10 )),0.$(( RANDOM % 10 ))"

awww img "$OUT" \
  --transition-type "$T" \
  --transition-angle "$ANGLE" \
  --transition-pos "$POS" \
  --transition-duration 1.5 \
  --transition-fps 60

upd-theme
