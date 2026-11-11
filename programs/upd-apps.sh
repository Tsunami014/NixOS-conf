#!/usr/bin/env bash
set -euo pipefail

HELP="Update specific flake inputs

If no arguments are given, will choose from this user's flake.
If a username is given, will choose from that user's flake.
If -s or --system is given, will choose from the system's flake.

This script runs the appropriate upd command afterwards

Optional flags:
  -pl or --plain   - use regular update functions instead of the fancy ones"

chose=""
cmd="nom"
ensure_one() {
    if [[ -n "$chose" ]]; then
        echo "Cannot have multiple targets!"
        exit 1
    fi
}
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -pl|--plain) cmd="nix" ;;
    -s|--system) ensure_one; chose="-s" ;;
    *) ensure_one; chose="$arg" ;;
  esac
done
if [ -z "$chose" ]; then chose="$USER"; fi

if [[ "$chose" == "-s" ]]; then
    prompt="system"
    pth="/etc/nixos"
else
    prompt="$chose"
    pth="/etc/nixos/users/$chose"
fi

if [ ! -e "$pth/flake.lock" ]; then
    echo "Unable to find lock file at '$pth/flake.lock'!"
    exit 1
fi

jq -r '.nodes.root.inputs | keys[]' "$pth/flake.lock" \
| fzf --multi --prompt "$prompt> " \
| xargs -r "$cmd" flake update --flake "$pth"

if [[ "$chose" == "-s" ]]; then
    sudo upd-system
elif [[ "$chose" == "$USER" ]]; then
    upd-user
else
    sudo -u "$chose" upd-user
fi
