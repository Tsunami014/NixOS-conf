#!/usr/bin/env bash
set -euo pipefail

sudo -v
mainFold="/etc/nixos"
cd "$mainFold"

fprint() {
    if [ $# -gt 1 ]; then
        printf "\e[1;%sm%s\e[0m\n" "$2" "$1"
    else
        printf "\e[1;93m%s\e[0m\n" "$1"
    fi
}

fprint "Syncing all..."
for folder in users/*; do
    name="$(basename "$folder")"
    if [ -d "$folder" ]; then
        fprint "Updating $name..." "94"
        cd "$folder"
        sudo -u "$name" sh ./sync.sh
        cd "$mainFold"
    else
        fprint "No sync script found for $name" "94"
    fi
done

fprint "Updating git..."
git add .

fprint "Running rebuild..."
sudo nixos-rebuild switch

fprint "Updating all..."
for folder in users/*; do
    name="$(basename "$folder")"
    fprint "Updating home manager for $name..." "94"
    sudo -u "$name" home-manager switch
done

printf "\e[1;92mDone!\e[0m"
