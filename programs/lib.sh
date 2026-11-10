# Prepended to every upd-* script

if [ -t 1 ] && [ -z "${NO_COLOR-}" ]; then
  C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
  C_RED=$'\e[1;31m'; C_GREEN=$'\e[1;32m'; C_YELLOW=$'\e[1;33m'
  C_BLUE=$'\e[1;34m'; C_MAGENTA=$'\e[1;35m'; C_CYAN=$'\e[1;36m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_MAGENTA=""; C_CYAN=""
fi

# Time in microseconds
_us() { local t=$EPOCHREALTIME; printf '%s' "${t//[.,]/}"; }
SCRIPT_START=$(_us)

# Microseconds -> "4.2s" / "1m05s"
fmt_dur() {
  local us=$1 s
  s=$(( us / 1000000 ))
  if (( s >= 60 )); then
    printf '%dm%02ds' $(( s / 60 )) $(( s % 60 ))
  else
    printf '%d.%01ds' "$s" $(( (us % 1000000) / 100000 ))
  fi
}

banner() {
  local text=" $1 " line
  printf -v line '%*s' "${#text}" ''
  line=${line// /─}
  printf '\n%s╭%s╮\n│%s│\n╰%s╯%s\n' "$C_MAGENTA" "$line" "$text" "$line" "$C_RESET"
}

good() { printf '%s✔ %s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
info() { printf '%sⓘ %s%s\n' "$C_DIM" "$*" "$C_RESET"; }
warn() { printf '%s⚠ %s%s\n' "$C_YELLOW" "$*" "$C_RESET" >&2; }
err()  { printf '%s✘ %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; }
die()  { err "$*"; exit 1; }

# y/n prompt; returns 0 on "y"
confirm() {
  local resp=""
  read -r -n 1 -p "$1 [y/n] " resp || true
  echo
  [ "$resp" = "y" ]
}

# ── Timed steps ─────────────────────────────────────────────────────────
STEP_NAMES=(); STEP_TIMES=(); STEP_ICONS=()
_cur_name=""; _cur_start=0

step() {
  _cur_name=$1
  _cur_start=$(_us)
  printf '\n%s▸ %s%s\n' "$C_CYAN" "$1" "$C_RESET"
}

_step_finish() {
  local dur
  dur=$(( $(_us) - _cur_start ))
  STEP_NAMES+=("$_cur_name"); STEP_TIMES+=("$dur"); STEP_ICONS+=("$1")
  printf '%s%s %s%s %s(%s)%s\n' "$2" "$1" "$_cur_name" "$C_RESET" "$C_DIM" "$(fmt_dur "$dur")" "$C_RESET"
}
step_done() { _step_finish "✔" "$C_GREEN"; }
step_fail() { _step_finish "✘" "$C_RED"; }

# run "Label" cmd args...  -> header, run, ✔/✘ with timing. Returns cmd's status.
run() {
  local label=$1 rc=0
  shift
  step "$label"
  "$@" || rc=$?
  if [ "$rc" -eq 0 ]; then step_done; else step_fail; fi
  return "$rc"
}

# Like run, but on failure prints the summary and exits.
must() {
  local rc=0
  run "$@" || rc=$?
  if [ "$rc" -ne 0 ]; then
    summary
    exit "$rc"
  fi
}

summary() {
  local i total
  total=$(( $(_us) - SCRIPT_START ))
  printf '\n%sSummary%s\n' "$C_MAGENTA" "$C_RESET"
  for i in "${!STEP_NAMES[@]}"; do
    printf '  %s %-40s %s%8s%s\n' "${STEP_ICONS[$i]}" "${STEP_NAMES[$i]}" "$C_DIM" "$(fmt_dur "${STEP_TIMES[$i]}")" "$C_RESET"
  done
  printf '  %s%-42s %8s%s\n' "$C_BOLD" "Total" "$(fmt_dur "$total")" "$C_RESET"
}
