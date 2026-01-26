#!/usr/bin/env bash
set -euo pipefail

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

syncf=$HOME/.config/home-manager/sync.sh
if [ -f "$syncf" ]; then
  fprint "Syncing..."
  cd "$(dirname "$syncf")"
  "$syncf"
else
  fprint "No sync script found"
fi

fprint "Updating git..."
git add .

fprint "Running user rebuild..."
home-manager switch

printf "\e[1;92mUpdated user!\e[0m"
