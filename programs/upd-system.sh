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
sudo -v

mainFold="/etc/nixos"

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

fprint "Updating permissions..."
sudo sh "$mainFold/perms.sh"

fprint "Updating git..."
sudo git -C "$mainFold" add .

fprint "Running system rebuild..."
if [ "${1-}" == "-ol" ]; then
    fprint "Using offline mode!"
    sudo nixos-rebuild switch --offline
else
    sudo nixos-rebuild switch
fi

printf "\e[1;92mUpdated system!\e[0m"
