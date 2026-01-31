#!/usr/bin/env bash
set -euo pipefail

mainFold=/etc/nixos
userFold="$mainFold/users/$USER"

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

if [ ! -d "$HOME" ]; then
  echo "Need a home directory! Try instead running upd-all"
  exit 1
fi

extended() { [ "${1:-}" != "--from-all" ]; }
if extended; then
  syncf="$userFold/sync.sh"
  if [ -f "$syncf" ]; then
    fprint "Syncing..."
    sh "$syncf" || fprint "Sync script failed!"
  else
    fprint "No sync script"
  fi
fi

fprint "Updating git..."
if ! git -C "$mainFold" rev-parse --git-dir >/dev/null 2>/tmp/err; then
  if grep -q "dubious ownership" /tmp/err; then
    fprint "Setting $mainFold as safe..."
    git config --global --add safe.directory "$mainFold"
  else
    fprint "Detected git problems in $mainFold!"
    exit 1
  fi
fi
if extended; then
  git -C "$mainFold" add .
fi

fprint "Running user rebuild..."
home-manager switch --flake "$userFold"

if extended; then
  printf "\e[1;92mUpdated user!\e[0m"
fi
