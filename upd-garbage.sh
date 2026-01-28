#!/usr/bin/env bash
set -euo pipefail

printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
if sudo -n true 2>/dev/null; then
    sudo nix-collect-garbage -d
else
    nix-collect-garbage -d
fi
printf "\e[1;92m%s\e[0m\n" "Collected garbage!"
