#!/usr/bin/env bash
set -euo pipefail

force=false
whole_user=false

for arg in "$@"; do
  case "$arg" in
    -9) force=true ;;
    -u) whole_user=true ;;
    -h|--help)
        echo "close [-9] [-u]
Pick a login session to kill gracefully

Options:
-9 - kill immediately without mercy instead
-u - terminate everything from one user
"; exit 0 ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

output=$(loginctl list-sessions)

header=$(head -n 1 <<< "$output")
mapfile -t rows < <(
  tail -n +2 <<< "$output" | head -n -2
)

if [ "${#rows[@]}" -eq 0 ]; then
  echo "No active sessions found."
  exit 0
fi

old_sessions=${#rows[@]}

if [ "$whole_user" = true ]; then
  declare -A session_counts=()

  for row in "${rows[@]}"; do
    user=$(awk '{print $3}' <<< "$row")
    session_counts["$user"]=$(( ${session_counts["$user"]:-0} + 1 ))
  done

  header=$(printf '%-16s %s\n' "USER" "SESSIONS")
  mapfile -t user_rows < <(
    for user in "${!session_counts[@]}"; do
      printf '%-16s %s\n' "$user" "${session_counts[$user]}"
    done | sort
  )

  selected=$(printf '%s\n' "${user_rows[@]}" \
    | fzf --header="$header" \
          --prompt="Select user to terminate> " \
          --layout=reverse)

  if [ -z "$selected" ]; then
    echo "Nothing selected, aborting."
    exit 0
  fi

  user=$(awk '{print $1}' <<< "$selected")
  user_session_count=$(awk '{print $2}' <<< "$selected")

  echo "Selected user '$user' ($user_session_count session(s))"
  echo "Terminating ALL sessions for user '$user'..."

  if [ "$force" = true ]; then
    sudo loginctl kill-user "$user"
  else
    sudo loginctl terminate-user "$user"
  fi

else
  selected=$(printf '%s\n' "${rows[@]}" \
    | fzf --header="$header" \
          --prompt="Select session to terminate> " \
          --layout=reverse)

  if [ -z "$selected" ]; then
    echo "Nothing selected, aborting."
    exit 0
  fi

  session_id=$(awk '{print $1}' <<< "$selected")
  user=$(awk '{print $3}' <<< "$selected")

  echo "Selected session $session_id (user: $user)"
  echo "Terminating session $session_id..."

  if [ "$force" = true ]; then
    sudo loginctl kill-session "$session_id"
  else
    sudo loginctl terminate-session "$session_id"
  fi
fi

# Give systemd a moment
sleep 0.1

new_sessions=$(loginctl list-sessions --no-legend | awk 'NF { count++ } END { print count+0 }')
echo "Done!"
echo "Sessions open: $old_sessions -> $new_sessions"
