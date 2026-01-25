#!/usr/bin/env bash
set -euo pipefail

sudo -v
echo "Syncing mutable config..."

MUT_DIR="$(pwd)/configMut"
SRC_DIR="$HOME/.config"

# Ensure the target directory exists
if [ ! -d "$MUT_DIR" ]; then
    echo "Error: $MUT_DIR does not exist"
    exit 1
fi

for folder in "$MUT_DIR"/*; do
    [ -d "$folder" ] || continue  # skip non-directories

    name="$(basename "$folder")"
    src_path="$SRC_DIR/$name"
    dest_path="$MUT_DIR/$name"

    if [ ! -d "$src_path" ]; then
        printf "Skipping $name — no matching directory in ~/.config"
        continue
    fi

    echo "Replacing $dest_path with $src_path"

    sudo rm -rf "$dest_path"

    sudo mkdir -p "$dest_path"
    sudo rsync -a --delete  "$src_path/" "$dest_path/"
done
