#!/usr/bin/env bash
set -euo pipefail

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
        echo "Skipping $name — no matching directory in ~/.config"
        continue
    fi

    echo "Replacing $dest_path with $src_path"

    rm -rf "$dest_path"

    mkdir -p "$dest_path"
    rsync -a --delete  "$src_path/" "$dest_path/"
done
