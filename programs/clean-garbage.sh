#!/usr/bin/env bash
set -euo pipefail
HELP="Clean the garbage! This means it will have to recache everything again.
This (probably) does different things when sudo is/isn't used.

This script runs 'upd-all' if sudo is used to recache stuff and fix generations and such.
Optional flags for upd-all:
-ol - run the operation completely offline (even if have wifi, don't use it)
"
case "${1-}" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -ol | "") ;;
    *) echo "Unknown option '$1'!"; echo "$HELP"; exit 1 ;;
esac

if sudo -n true 2>/dev/null; then
    echo "Using sudo to update garbage!"
else
    echo "Not using sudo to update garbage!"
fi

read -r -n 1 -p "Are you sure you want to collect garbage? This may make nix have to redownload a lot of cached stuff. [y/n] " RESP
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
if sudo -n true 2>/dev/null; then
    printf "\e[1;93m%s\e[0m\n" "Updating everything again..."
    sudo upd-all "$@"
else
    echo "I recommend you run 'upd-all' to rebuild cache"
fi
