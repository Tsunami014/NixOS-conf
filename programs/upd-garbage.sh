#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos

HELP="Clean the garbage! This means it will have to recache everything again.

Optional flags for cleaning:
  -usr - only collect user garbage, not root or any other user (does not require sudo)
  -root - only collect garbage from root user

This script runs the appropriate upd command for the requirement (upd-user if -usr, upd-system if -root, else upd-all) to fix generations and redownload some important things so you can update offline again
Optional flags for update scripts:
$(upd-all --flags)"
updargs=()
upd="all"
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -usr | -root)
        if [ "$upd" != "all" ]; then
            echo "Cannot have -usr and -root at the same time!"
            exit 1
        fi
        upd="${arg:1}"
    ;;

    -ol) updallargs+=("$arg") ;;
    *) echo "Unknown option '$arg'!"; echo "$HELP"; exit 1 ;;
  esac
done

read -r -n 1 -p "Are you sure you want to collect garbage? This may make nix have to redownload a lot of cached stuff. [y/n] " RESP
echo
if [ "$RESP" != "y" ]; then
    echo "Not cleaning."
    exit 1
fi

printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
case "$upd" in
    all)
        updscript="all"
        printf "\e[1;94m%s\e[0m\n" "Cleaning root..."
        sudo nix-collect-garbage -d
        for folder in "$mainFold"/users/*; do
            name="$(basename "$folder")"
            printf "\e[1;94m%s\e[0m\n" "Cleaning $name..."
            sudo -iu "$name" nix-collect-garbage -d
        done
    ;;
    root) updscript="system"; sudo nix-collect-garbage -d ;;
    usr) updscript="user"; nix-collect-garbage -d ;;
esac

printf "\e[1;92m%s\e[0m\n" "Collected garbage!"

"upd-$updscript" "${updargs[@]}"
