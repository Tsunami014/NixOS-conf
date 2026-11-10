#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos

FLAGS=$(cat << EOF
  -t or --trash - ONLY clean local cache files, not nixos cache
  -s - clean system garbage only
  -a - clean both system and user garbage
  -k Nd or --keep Nd - keep generations newer than N days (default 7d), or 'all' to delete every old generation
EOF
);if [ "${1-}" = "--flags" ]; then
    upd-all --flags; echo "$FLAGS"; exit 0
fi

HELP="Clean the garbage!
If cleaning system, will have to recache everything again, and will probably require wifi.
This by default only cleans the user garbage, but can clean system garbage too (requiring root).
Old generations are expired first, then the store is collected once at the end.

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
keep="7d"
while [ $# -gt 0 ]; do
  arg=$1; shift
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
    -k | --keep)
        if [ $# -eq 0 ]; then
            echo "$arg needs a value!"; exit 1
        fi
        keep=$1; shift
    ;;
    -k=* | --keep=*) keep="${arg#*=}" ;;

    *)
        if [[ ${flag_map["$arg"]+_} ]]; then
            updargs+=("${flag_map["$arg"]}")
        else
            echo "Unknown option '$arg'!"; echo "$HELP"; exit 1
        fi
    ;;
  esac
done

if ! [[ "$keep" =~ ^([1-9][0-9]*d|all)$ ]]; then
    echo "Invalid --keep value '$keep' (use e.g. 7d, or 'all')!"
    exit 1
fi

nixkeep=$keep
if [ "$keep" = "all" ]; then
    nixkeep="old"
    keeptxt="no old generations"
else
    keeptxt="generations from the last ${keep%d} days"
fi

case "$upd" in
    a) updscript="all"; scope="THE SYSTEM AND ALL USERS" ;;
    s) updscript="system"; scope="ONLY THE SYSTEM" ;;
    u) updscript="user"; scope="THIS USER" ;;
esac
if $onlytrash; then
    trashtxt="ONLY THE TRASH"
    suff=""
else
    trashtxt="ALL THE GARBAGE (keeping $keeptxt)"
    suff=" You may need to redownload stuff."
fi
banner "Collect garbage"
if ! confirm "Are you sure you want to collect $trashtxt for $scope?$suff"; then
    warn "Not cleaning."
    exit 1
fi

expire_user_profiles() {
    local keep=$1 base p
    for base in "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles" "/nix/var/nix/profiles/per-user/$USER"; do
        for p in profile home-manager; do
            if [ -e "$base/$p" ]; then
                nix-env --profile "$base/$p" --delete-generations "$keep"
            fi
        done
    done
}

expire_user_as() { # $1 = user name
    {
        declare -f expire_user_profiles
        echo "expire_user_profiles $nixkeep"
    } | sudo -iu "$1" bash
}

clean_trash() { # $1 = home dir
    local dir
    for dir in "$1/.local/share/Trash" "$1/.cache"; do
        if sudo test -d "$dir"; then
            # To keep nix's eval/fetch cache, add: ! -name nix
            sudo find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
        fi
    done
}

usernames=()
for folder in "$mainFold"/users/*; do
    usernames+=("$(basename "$folder")")
done

free_before=$(df --output=avail -B1 /nix/store | tail -n 1 | tr -d ' ')

# Expire generations everywhere
if ! $onlytrash; then
    if [ "$upd" = "a" ] || [ "$upd" = "s" ]; then
        step "Expiring system generations"
        sudo nix-env -p /nix/var/nix/profiles/system --delete-generations "$nixkeep"
        step_done
    fi
    if [ "$upd" = "a" ]; then
        for name in "${usernames[@]}"; do
            step "Expiring $name's generations"
            expire_user_as "$name"
            step_done
        done
    elif [ "$upd" = "u" ]; then
        step "Expiring $USER's generations"
        expire_user_profiles "$nixkeep"
        step_done
    fi

    # Collect garbage after everything is expired
    step "Collecting the nix store"
    if [ "$upd" = "u" ]; then
        nix-collect-garbage
    else
        sudo nix-collect-garbage
    fi
    step_done
fi

# Trash and caches
if [ "$upd" = "a" ]; then
    for name in "${usernames[@]}"; do
        step "Cleaning trash for $name"
        clean_trash "/home/$name"
        step_done
    done
elif [ "$upd" = "u" ]; then
    step "Cleaning trash"
    clean_trash "/home/$USER"
    step_done
fi

free_after=$(df --output=avail -B1 /nix/store | tail -n 1 | tr -d ' ')
freed=$(( free_after - free_before ))
summary
printf '\n'; good 'Collected garbage!'
if (( freed > 0 )); then
    info "Freed about $(numfmt --to=iec "$freed")"
fi

"upd-$updscript" "${updargs[@]}"
