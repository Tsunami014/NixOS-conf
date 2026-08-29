#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos

FLAGS=$(cat << EOF
  -t or --trash - ONLY clean local cache files, not nixos cache
  -s - clean system garbage only
  -a - clean both system and user garbage
EOF
);if [ "${1-}" = "--flags" ]; then
    upd-all --flags; echo "$FLAGS"; exit 0
fi

HELP="Clean the garbage!
If cleaning system, will have to recache everything again, and will probably require wifi.
This by default only cleans the user garbage, but can clean system garbage too (requiring root).

Optional flags for cleaning:
$FLAGS

This script runs the appropriate upd command for the requirement (upd-user if -usr, upd-system if -root, else upd-all) to fix generations and redownload some important things so you can update offline again
Optional flags for update scripts:
$(upd-all --flags)"

declare -A flag_map
outmap=""
while IFS='=' read -r key value; do
  flag_map["$key"]="$value"
  outmap+="$key=$value
"
done < <(upd-all --map)
if [ "${1-}" = "--map" ]; then
  printf "%s" "${outmap%?}"; echo
  echo "-t=--trash"; echo "--trash=--trash"; echo "-s=-s"; echo "-a=-a"
  exit 0
fi

updargs=()
upd="u"
onlytrash=false
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    -t | --trash) onlytrash=true ;;
    -a | -s)
        if [ "$upd" != "u" ]; then
            echo "Cannot have -s and -a at the same time!"
            exit 1
        fi
        upd="${arg:1}"
    ;;

    *)
        if [[ ${flag_map["$arg"]+_} ]]; then
            updargs+=("${flag_map["$arg"]}")
        else
            echo "Unknown option '$arg'!"; echo "$HELP"; exit 1
        fi
    ;;
  esac
done

case "$upd" in
    a) updscript="all"; scope="ALL USERS" ;;
    s) updscript="system"; scope="ONLY THE SYSTEM" ;;
    u) updscript="user"; scope="THIS USER" ;;
esac
if $onlytrash; then
    trashtxt="ONLY THE TRASH"
    suff=""
else
    trashtxt="ALL THE GARBAGE"
    suff=" You may need to redownload stuff."
fi
read -r -n 1 -p "Are you sure you want to collect $trashtxt for $scope?$suff [y/n] " RESP
echo
if [ "$RESP" != "y" ]; then
    echo "Not cleaning."
    exit 1
fi

printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
case "$upd" in
    a)
        printf "\e[1;94m%s\e[0m\n" "Cleaning root..."
        sudo nix-collect-garbage -d
        for folder in "$mainFold"/users/*; do
            name="$(basename "$folder")"
            printf "\e[1;94m%s\e[0m\n" "Cleaning $name..."
            if ! $onlytrash; then
                sudo -iu "$name" nix-collect-garbage -d
            fi
            echo "Cleaning trash for $name..."
            sudo rm -rf /home/"$name"/.local/share/Trash/* /home/"$name"/.cache/*
            echo "Done cleaning trash for $name!"
        done
    ;;
    s)
        if ! $onlytrash; then
            sudo nix-collect-garbage -d
        fi
    ;;
    u)
        if ! $onlytrash; then
            nix-collect-garbage -d
        fi
        echo "Cleaning trash..."
        sudo rm -rf /home/"$USER"/.local/share/Trash/* /home/"$USER"/.cache/*
        echo "Done cleaning trash!"
    ;;
esac

printf "\e[1;92m%s\e[0m\n" "Collected garbage!"

"upd-$updscript" "${updargs[@]}"
