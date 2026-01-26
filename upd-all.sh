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

upd-system

fprint "\nUpdating all users..."
for folder in users/*; do
    name="$(basename "$folder")"
    fprint "Running user rebuild for $name..." "94"
    sudo -u "$name" home-manager switch
done

fprint "Updated users!" "92"
fprint "Finished updating system and users!" "95"
