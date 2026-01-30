#!/usr/bin/env bash
set -euo pipefail

read -r -n 1 -p "Are you sure you want to collect garbage? [y/n] " RESP
echo
if [ "$RESP" != "y" ]; then
    echo "Quitting..."
    exit 1
fi

printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
if sudo -n true 2>/dev/null; then
    sudo nix-collect-garbage -d
else
    nix-collect-garbage -d
fi
printf "\e[1;92m%s\e[0m\n" "Collected garbage!"
