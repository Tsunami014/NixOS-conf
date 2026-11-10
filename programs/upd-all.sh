#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos

FLAGS=$(cat << EOF
  -ol or --offline - run the operation completely offline (even if have wifi, don't use it)
  -up or --upgrade - upgrade the packages from source
  -usr or --users  - Only update all users, not the system
EOF
);if [ "${1-}" = "--flags" ]; then
    echo "$FLAGS"; exit 0
fi
declare -A flag_map
outmap=""
map() {
  value="${2:-$1}"
  outmap+="$1=$value
"
  flag_map["$1"]="$value"
  if [[ "$1" != "$value" ]]; then
    outmap+="$2=$2
"
    flag_map["$2"]="$2"
  fi
}
map "-ol" "--offline"
map "-up" "--upgrade"
map "-usr" "--users"
if [ "${1-}" = "--map" ]; then
  printf "%s" "${outmap%?}"
  exit 0
fi

HELP="Update the system and every user

Optional flags:
$FLAGS"

updargs=()
usersOnly=false
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -usr | --users) usersOnly=true ;;
    *)
        if [[ ${flag_map["$arg"]+_} ]]; then
            updargs+=("${flag_map["$arg"]}")
        else
            echo "Unknown option '$arg'!"; echo "$HELP"; exit 1
        fi
    ;;
  esac
done
sudo -v

banner "Update everything"

if ! $usersOnly; then
    must "System" sudo upd-system --from-all "${updargs[@]}"
fi

for folder in "$mainFold"/users/*; do
    name=$(basename "$folder")
    must "User: $name" sudo -iu "$name" upd-user --from-all "${updargs[@]}"
done

for folder in "$mainFold"/users/*; do
    name=$(basename "$folder")
    if [ -f "$folder/sync.sh" ]; then
        if ! run "Sync: $name" sudo -u "$name" sh "$folder/sync.sh" "${updargs[@]}"; then
            warn "Sync script failed for $name!"
        fi
    else
        info "No sync script for $name"
    fi
done

summary
printf '\n'; good 'Finished updating system and users!'
