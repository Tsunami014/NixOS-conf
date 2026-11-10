#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos

FLAGS=$(cat << EOF
  -ol or --offline - run the operation completely offline (even if have wifi, don't use it)
  -up or --upgrade - upgrade the packages from source
  -pl or --plain   - use regular update functions instead of the fancy ones
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
  map "-pl" "--plain"
  exit 0
fi

HELP="Update system

Optional flags:
$FLAGS"

args=()
upgrade=false
offline=false
plain=false
fromAll=false
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    --from-all) fromAll=true ;; # Internal: called by upd-all (quieter output)
    -ol|--offline) offline=true; args+=("--offline") ;;
    -up|--upgrade) upgrade=true; args+=("--upgrade") ;;
    -pl|--plain) plain=true ;;
    *) echo "Unknown option '$arg'!"; echo "$HELP"; exit 1 ;;
  esac
done
sudo -v

build_system() {
  local offline_args=()
  if $offline; then offline_args=(--offline); fi
  if $plain || ! command -v nom > /dev/null 2>&1; then
    return 0 # nixos-rebuild will build it itself
  fi
  nom build --no-link "${offline_args[@]}" \
    "$mainFold#nixosConfigurations.$(hostname).config.system.build.toplevel"
}

$fromAll || banner "Update system"

must "Fixing permissions" sudo sh "$mainFold/perms.sh"
must "Staging config in git" sudo git -C "$mainFold" add .

if $upgrade; then
  if $offline; then
    die "Cannot upgrade packages offline!"
  fi
  must "Upgrading flake inputs" nix flake update --flake "$mainFold"
fi

if $offline; then
  step "Rebuilding system (offline)"
else
  step "Rebuilding system"
fi

must "Building system" build_system
must "Switching to new system" sudo nixos-rebuild switch "${args[@]}"

if ! $fromAll; then summary; fi
printf '\n'; good "Updated system!"
