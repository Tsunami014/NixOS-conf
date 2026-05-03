#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos

HELP="Clean the generations for system and current user (and runs upd-system at the end to fix boot screen)

Options for cleaning:
  old - Same as +1 (keep only the last generation)
  +N - Keep only the last N generations
  Nd - Keep only the last N days of generations
N must be a number > 0

Optional flags for cleaning:
  -usr - Only clean this user's generations (no root required)
  -root - Only clean system's generations

Optional flags for updating system:
$(upd-system --flags)"
if [ ! -v 1 ]; then
    echo "$HELP"
    exit 0
fi

declare -A flag_map
while IFS='=' read -r key value; do
  flag_map["$key"]="$value"
done < <(upd-system --map)

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

    old) num="1"; type="+" ;;
    *)
        if [[ ${flag_map["$arg"]+_} ]]; then
            updargs+=("${flag_map["$arg"]}")
        elif [[ $1 =~ ^\+([1-9][0-9]*)+$ ]]; then
            num="${BASH_REMATCH[1]}"
            type="+"
        elif [[ $1 =~ ^([1-9][0-9]*)d$ ]]; then
            num="${BASH_REMATCH[1]}"
            type="d"
        else
            echo "Unknown option '$1'!"
            echo "$HELP"
            exit 1
        fi
    ;;
  esac
done
if [ ! -v num ] || [ ! -v type ]; then
    echo "Clean option not specified!"
    echo "$HELP"
    exit 1
fi

if [ "$upd" = "none" ] && ! sys; then
    echo "Not cleaning anything..?"
    exit 1
fi

if [ "${type}${num}" = "+1" ]; then
    txt=""
elif [ "$type" = + ]; then
    txt=" $num"
elif [ "$type" = d ]; then
    txt=" $num days of"
fi
case "$upd" in
    all) txt2="everywhere" ;;
    root) txt2="the system" ;;
    usr) txt2="this user" ;;
esac
echo "Are you sure you want to delete the previous$txt generations for $txt2?"
echo "(Only do this if you are confident your system is not broken)"
read -r -n 1 -p "[y/n] " RESP
echo
if [ "$RESP" != "y" ]; then
    echo "Not deleting."
    exit 0
fi

if [ "$upd" != "usr" ]; then
    printf "\e[1;93m%s\e[0m\n" "Deleting system generations..."
    case "$type" in
        +) cleansys="+$num" ;;
        d) cleansys="${num}d" ;;
    esac
    if [ "$cleansys" == "0d" ]; then
        cleansys="old"
    fi
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations "$cleansys"
fi

cleanUsr() {
    printf "\e[1;94m%s\e[0m\n" "Cleaning $USER's generations..."
    case "$type" in
        +)
            curId=$(home-manager generations | grep "(current)" | awk 'END {print $5}')
            home-manager remove-generations "$(
                home-manager generations | awk -v cutoff="$((curId - num))" '$5 < cutoff { print $5 }'
            )"
        ;;
        d)
            home-manager expire-generations "-$num days"
        ;;
    esac
    upd-user --from-all "${updargs[@]}"
}
if [ "$upd" != "root" ]; then
    printf "\e[1;93m%s\e[0m\n" "Deleting user generations..."
    if [ "$upd" = "usr" ]; then
        cleanUsr
    else
        for folder in "$mainFold"/users/*; do
            {
              declare -f cleanUsr
              echo cleanUsr
            } | sudo -iu "$(basename "$folder")" bash
        done
    fi
fi

printf "\e[1;92m%s\e[0m\n" "Deleted generations!"
case "$upd" in
    all|root) updscript="system" ;;
    usr) updscript="user" ;;
esac
"upd-$updscript" "${updargs[@]}"
