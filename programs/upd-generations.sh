#!/usr/bin/env bash
set -euo pipefail
HELP="Update scripts

Optional flags:
-ol - run the operation completely offline (even if have wifi, don't use it)
"
case "${1-}" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -ol | "") ;;
    *) echo "Unknown option '$1'!"; echo "$HELP"; exit 1 ;;
esac

read -r -n 1 -p "Are you sure you want to delete previous generations? (Only do this if you are confident your system is not broken) [y/n] " RESP
echo
if [ "$RESP" != "y" ]; then
    echo "Quitting..."
    exit 1
fi

printf "\e[1;93m%s\e[0m\n" "Deleting previous generations..."
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old

printf "\e[1;92m%s\e[0m\n" "Deleted previous generations!"
printf "\e[1;93m%s\e[0m\n" "Updating system..."
upd-system "$@"
