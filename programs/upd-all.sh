#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos

FLAGS=$(cat << EOF
  -ol or --offline - run the operation completely offline (even if have wifi, don't use it)
  -up or --upgrade - upgrade the packages from source
EOF
);if [ "${1-}" = "--flags" ]; then
    echo "$FLAGS"; exit 0
fi
declare -A flag_map
outmap=""
map() {
  value="${2:-$1}"
  outmap+="$1=$value\n"
  flag_map["$1"]="$value"
  if [[ "$1" != "$value" ]]; then
    outmap+="$2=$2\n"
    flag_map["$2"]="$2"
  fi
}
map "-ol" "--offline"
map "-up" "--upgrade"
if [ "${1-}" = "--map" ]; then
  echo "${outmap%?}"
  exit 0
fi

HELP="Update the system and every user

Optional flags:
$FLAGS"

updargs=()
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
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

fprint() {
    if [ $# -gt 1 ]; then
        printf "\e[1;%sm%s\e[0m\n" "$2" "$1"
    else
        printf "\e[1;93m%s\e[0m\n" "$1"
    fi
}

syncall() {
    fprint "Syncing all for $1..."
    for folder in "$mainFold"/users/*; do
        name=$(basename "$folder")
        if [ -f "$folder/sync.sh" ]; then
            fprint "Syncing $name..." "94"
            sudo -u "$name" sh "$folder/sync.sh" "$1" "${updargs[@]}" || fprint "Sync script failed!" "94"
        else
            fprint "No sync script for $name" "94"
        fi
    done
}
syncall before

sudo upd-system "${updargs[@]}" 

echo
fprint "Updating all users..."
for folder in "$mainFold"/users/*; do
    name=$(basename "$folder")
    fprint "Updating $name..." "94"
    sudo -iu "$name" upd-user --from-all "${updargs[@]}"
    echo
done
fprint "Updated users!" "92"

syncall after

fprint "Finished updating system and users!" "95"
