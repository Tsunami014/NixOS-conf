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
upgrade=false
offline=false
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -ol|--offline) offline=true; args+=("--offline") ;;
    -up|--upgrade) upgrade=true; args+=("--upgrade") ;;
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

if $upgrade; then
    if $offline; then
        fprint "Cannot upgrade packages offline!"
        exit 1
    fi
    fprint "Upgrading packages..."
    nix flake update --flake "$mainFold"
fi
fprint "Running system rebuild..."
if $offline; then
  fprint "Using offline mode!"
fi
sudo nixos-rebuild switch "${args[@]}"

printf "\e[1;92mUpdated system!\e[0m"
