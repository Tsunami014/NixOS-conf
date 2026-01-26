#!/usr/bin/env bash
set -euo pipefail
sudo -v

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

fprint "Updating git..."
git add .

fprint "Running system rebuild..."
sudo nixos-rebuild switch

printf "\e[1;92mUpdated system!\e[0m"
