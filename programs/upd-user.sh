#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos
userFold="$mainFold/users/$USER"

FLAGS=$(cat << EOF
  -ol - run the operation completely offline (even if have wifi, don't use it)
EOF
);if [ "${1-}" = "--flags" ]; then
    echo "$FLAGS"; exit 0
fi
HELP="Update this user

Optional flags:
$FLAGS"

fromAll=false
offline=false
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    --from-all) fromAll=true ;;
    -ol) offline=true ;;
    *) echo "Unknown option '$arg'!"; echo "$HELP"; exit 1 ;;
  esac
done

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

if [ ! -d "$HOME" ]; then
    echo "Need a home directory! Try instead running upd-all"
    exit 1
fi

sync() {
    syncf="$userFold/sync.sh"
    if [ -f "$syncf" ]; then
        fprint "Syncing $1..."
        sh "$syncf" "$@" || fprint "Sync script failed!"
    else
        fprint "No sync script for syncing $1"
    fi
}
if ! $fromAll; then
    sync before "$@"
fi

fprint "Updating git..."
if ! git -C "$mainFold" rev-parse --git-dir >/dev/null 2>/tmp/err; then
    if grep -q "dubious ownership" /tmp/err; then
        fprint "Setting $mainFold as safe..."
        git config --global --add safe.directory "$mainFold"
    else
        fprint "Detected git problems in $mainFold!"
        exit 1
    fi
fi
if ! $fromAll; then
    git -C "$mainFold" add .
fi

fprint "Running user rebuild..."
if $offline; then
    fprint "Using offline mode! The wifi will be temporarily disabled."
    wifi_on() { nmcli radio wifi on; }
    trap wifi_on ERR
    nmcli radio wifi off
    home-manager switch --flake "$userFold"
    wifi_on
else
    home-manager switch --flake "$userFold"
fi

if ! $fromAll; then
    sync after "$@"
fi

if ! $fromAll; then
   printf "\e[1;92mUpdated user!\e[0m"
fi
