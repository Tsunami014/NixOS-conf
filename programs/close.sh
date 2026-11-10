#!/usr/bin/env bash
set -euo pipefail

case "${1-}" in
    --help | -h | help)
        echo "close
Pick a login session to kill gracefully
"; exit 0 ;;
esac

output=$(w | awk 'NR==2 || /[[:alnum:]_]+ +tty/')

header=$(head -n 1 <<< "$output")
mapfile -t rows < <(
  tail -n +2 <<< "$output"
)

if [ "${#rows[@]}" -eq 0 ]; then
  echo "No active sessions found."
  exit 0
fi

old_sessions=${#rows[@]}

choose=$(printf '%s\n' "${rows[@]}" \
  | fzf --header="$header" \
        --prompt="Select session to terminate> " \
        --layout=reverse)

if [ -z "$choose" ]; then
  exit 0
fi

tty=$(awk '{print $2}' <<< "$choose")
echo "Terminating $tty..."
sudo pkill -TERM -t "$tty"

# Give systemd a moment
sleep 0.1

new_sessions=$(w | awk '/[[:alnum:]_]+ +tty/{count++} END {print count+0}')
echo "Done!"
echo "Sessions open: $old_sessions -> $new_sessions"
