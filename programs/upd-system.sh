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
if [ "${1-}" = "--map" ]; then
  map() {
    echo "$1=${2:-$1}";
    if [[ "$1" != "$2" ]]; then echo "$2=$2"; fi
  }
  map "-ol" "--offline"
  map "-up" "--upgrade"
  exit 0
fi

HELP="Update system

Optional flags:
$FLAGS"

args=()
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -ol|--offline) args+=("--offline") ;;
    -up|--upgrade) args+=("--upgrade") ;;
    *) echo "Unknown option '$arg'!"; echo "$HELP"; exit 1 ;;
  esac
done
sudo -v

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

fprint "Updating permissions..."
sudo sh "$mainFold/perms.sh"

fprint "Updating git..."
sudo git -C "$mainFold" add .

fprint "Running system rebuild..."
for it in "${args[@]}"; do
  case "$it" in
    --offline) fprint "Using offline mode!" ;;
    --upgrade) fprint "Upgrading packages!" ;;
  esac
done
sudo nixos-rebuild switch "${args[@]}"

printf "\e[1;92mUpdated system!\e[0m"
