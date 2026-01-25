#!/usr/bin/env bash
set -euo pipefail

./sync.sh

REG_DIR="./config"
MUT_DIR="./configMut"
CONF_DIR="$HOME/.config"

for item in "$@"; do
    if [ -d "$CONF_DIR/$item" ]; then
        echo "Removing existing config for $item"
        rm -rf "$CONF_DIR/$item"
    fi
    if [ -d "$REG_DIR/$item" ]; then
        echo "Moving $item from regular to mut"
        mv "$REG_DIR/$item" "$MUT_DIR/"
        continue
    fi
    if [ -d "$MUT_DIR/$item" ]; then
        echo "Moving $item from mut to regular"
        mv "$MUT_DIR/$item" "$REG_DIR/"
        continue
    fi
    echo "Folder '$item' not found in either directory"
done
git add .
echo "Done!"
upd-user
