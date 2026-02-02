#!/usr/bin/env bash
set -euo pipefail
HELP="Update scripts

Optional flags:
-ol - run the operation completely offline (even if have wifi, don't use it)
"
case "${1-}" in
    --help | -help | -h) echo "$HELP"; ecit 0 ;;
    -ol | --from-all | "") ;;
    *) echo "Unknown option '$1'!"; echo "$HELP"; exit 1 ;;
esac

mainFold=/etc/nixos
userFold="$mainFold/users/$USER"

fprint() {
    printf "\e[1;93m%s\e[0m\n" "$1";
}

if [ ! -d "$HOME" ]; then
    echo "Need a home directory! Try instead running upd-all"
    exit 1
fi

extended() { [ "${1:-}" != "--from-all" ]; }
if extended; then
    syncf="$userFold/sync.sh"
    if [ -f "$syncf" ]; then
        fprint "Syncing..."
        sh "$syncf" "$@" || fprint "Sync script failed!"
    else
        fprint "No sync script"
    fi
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
if extended; then
    git -C "$mainFold" add .
fi

fprint "Running user rebuild..."
if [ "${1-}" == "-ol" ]; then
    "$(nix path-info --offline "$userFold#homeConfigurations.$USER.activationPackage")"/activate
else
    home-manager switch --flake "$userFold"
fi

if extended; then
   printf "\e[1;92mUpdated user!\e[0m"
fi
