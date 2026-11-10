#!/usr/bin/env bash
set -euo pipefail
mainFold=/etc/nixos
userFold="$mainFold/users/$USER"

FLAGS=$(cat << EOF
  -ol or --offline - run the operation completely offline (even if have wifi, don't use it)
  -up or --upgrade - upgrade the packages from source
  -pl or --plain   - use regular update functions instead of the fancy ones
EOF
);if [ "${1-}" = "--flags" ]; then
    echo "$FLAGS"; exit 0
fi
if [ "${1-}" = "--map" ]; then
  map() {
    echo "$1=${2:-$1}";
    if [[ "$1" != "$2" ]]; then echo "$2=$2"; fi
  }
  map "-ol" "--offline"
  map "-up" "--upgrade"
  map "-pl" "--plain"
  exit 0
fi

HELP="Update this user

Optional flags:
$FLAGS"

fromAll=false
offline=false
upgrade=false
plain=false
for arg in "$@"; do
  case "$arg" in
    --help | -help | -h) echo "$HELP"; exit 0 ;;
    --from-all) fromAll=true ;;
    -ol|--offline) offline=true ;;
    -up|--upgrade) upgrade=true ;;
    -pl|--plain) plain=true ;;
    *) echo "Unknown option '$arg'!"; echo "$HELP"; exit 1 ;;
  esac
done

if [ ! -d "$HOME" ]; then
    echo "Need a home directory! Try instead running upd-all"
    exit 1
fi

hm_switch() {
  local out offline_args=()
  if $offline; then offline_args=(--offline); fi
  if $plain || ! command -v nom > /dev/null 2>&1; then
    home-manager switch --flake "$userFold"
    return
  fi
  out=$(nom build --no-link --print-out-paths "${offline_args[@]}" \
    "$userFold#homeConfigurations.$USER.activationPackage") || return $?
  "$out/activate"
}

check_git() {
  local gitout
  if ! gitout=$(git -C "$mainFold" rev-parse --git-dir 2>&1 > /dev/null); then
    if grep -q "dubious ownership" <<< "$gitout"; then
      info "Setting $mainFold as safe..."
      git config --global --add safe.directory "$mainFold"
    else
      err "Detected git problems in $mainFold!"
      return 1
    fi
  fi
  if ! $fromAll; then
    git -C "$mainFold" add .
  fi
}

$fromAll || banner "Update user: $USER"

must "Checking git" check_git

if $upgrade; then
  if $offline; then
    die "Cannot upgrade packages offline!"
  fi
  must "Upgrading flake inputs" nix flake update --flake "$userFold"
fi

if $offline; then
  warn "Offline mode! The wifi will be temporarily disabled."
  trap 'nmcli radio wifi on' EXIT
  nmcli radio wifi off
fi
must "Rebuilding home" hm_switch
if $offline; then
  nmcli radio wifi on
fi

if ! $fromAll; then
  syncf="$userFold/sync.sh"
  if [ -f "$syncf" ]; then
    if ! run "Syncing config links" sh "$syncf" "$@"; then
      warn "Sync script failed!"
    fi
  else
    info "No sync script for $USER"
  fi
  summary
  printf '\n'; good "Updated user!"
else
  printf '\n'; good "Updated $USER!"
fi
