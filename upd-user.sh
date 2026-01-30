#!/usr/bin/env bash
set -euo pipefail

mainFold="/etc/nixos"
userFold="$mainFold/users/$USER"

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

if [ ! -d "$HOME" ]; then
  echo "Need a home directory! Try instead running upd-all"
  exit 1
fi

if [ "${1:-}" != "--from-all" ]; then
  syncf="$userFold/sync.sh"
  if [ -f "$syncf" ]; then
    fprint "Syncing..."
    sh "$syncf" || fprint "Sync script failed!"
  else
    fprint "No sync script"
  fi
fi

fprint "Checking git..."
if ! git -C /etc/nixos rev-parse --git-dir >/dev/null; then
  if grep -q "dubious ownership" err; then
    fprint "Setting /etc/nixos as safe..."
    git config --global --add safe.directory /etc/nixos
  else
    fprint "Detected git problems in /etc/nixos!"
    exit 1
  fi
fi

fprint "Running user rebuild..."
home-manager switch --flake "$userFold"

if [ "${1:-}" != "--from-all" ]; then
  printf "\e[1;92mUpdated user!\e[0m"
fi
