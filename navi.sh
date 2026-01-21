#!/usr/bin/env bash

HINTS=$(cat <<'EOF'
Mount external drive
## Find drive (in /dev)
lsblk -l
## Mount drive to any dir, e.g. /mnt
#sudo mount /dev/sda1 /mnt

Unmount external drive
#sudo umount -r /mnt
EOF
)


HELP="NAVI
 
Run without arguments to launch fzf to search for something you want help with!
 
Once selected it will be printed and copied to the clipboard! Commands requiring you to do anything or that are unsafe are always commented out.
Best usage: paste entirely into the terminal and press enter, then press up to go through each command!"
HINTS+="

help
$HELP
"

# If called with an argument then return that hint for the preview
if [[ -n "$1" ]]; then
    HINTS+="

-h
$HELP

--help
$HELP"
    name="$1"
    awk -v RS='' -v name="$name" '
        {
            # first line = name
            split($0, lines, "\n")
            if (lines[1] == name) {
                # print everything except the first line
                for (i=2; i<=length(lines); i++) print lines[i]
            }
        }
    ' <<< "$HINTS"
    exit 0
fi

# Else run interactively!
NAMES=$(awk -v RS='' '
    {
        split($0, lines, "\n")
        print lines[1]
    }
' <<< "$HINTS")

selected=$(printf "%s\n" "$NAMES" | fzf \
    --prompt="Hint> " \
    --preview="$0 {}" \
    --preview-window=wrap)

if [[ -n "$selected" ]]; then
    hint="$("$0" "$selected")"
    printf "%s\n" "$hint"
    printf "%s" "$hint" | wl-copy
fi
