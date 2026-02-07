#!/usr/bin/env bash
set -euo pipefail

if [[ ! -v 1 ]]; then
    echo "Argument must be a number for relative position of new workspace
+ moves it after (down), - moves it before (up)
0 moves before current, 1 moves after

--take after takes the current window to the new workspace"
    exit 0
fi

cur=$(niri msg workspaces | grep -P -o "(?<=\\* )\\d+")
move=$(($cur - 2 + $1))

if [[ ! -v move ]]; then
    echo "Could not perform math with this: $1"
    exit 1
fi

if [ "${2-}" == "--take" ]; then
    niri msg action move-window-to-workspace 0
else
    niri msg action focus-workspace 0
fi

for ((i=0; i<"$move"; i++)); do
    echo "$i"
    niri msg action move-workspace-down
done
