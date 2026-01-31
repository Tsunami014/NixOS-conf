#!/usr/bin/env bash
set -euo pipefail
sudo -v

oldFold=$(pwd)
mainFold="/etc/nixos"

fprint() {
    if [ $# -gt 1 ]; then
        printf "\e[1;%sm%s\e[0m\n" "$2" "$1"
    else
        printf "\e[1;93m%s\e[0m\n" "$1"
    fi
}

fprint "Syncing all..."
for folder in "$mainFold"/users/*; do
    name=$(basename "$folder")
    if [ -d "$folder/sync.sh" ]; then
        fprint "Syncing $name..." "94"
        cd "$folder"
        sudo -u "$name" sh ./sync.sh || fprint "Sync script failed!" "94"
    else
        fprint "No sync script for $name" "94"
    fi
done
cd "$oldFold"

upd-system

echo
fprint "Updating all users..."
for folder in "$mainFold"/users/*; do
    name=$(basename "$folder")
    fprint "Updating $name..." "94"
    sudo -iu "$name" upd-user --from-all
    echo
done

fprint "Updated users!" "92"
fprint "Finished updating system and users!" "95"
