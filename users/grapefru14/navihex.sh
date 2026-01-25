#!/usr/bin/env bash

GESTURE_FILE="$HOME/.config/hexecute/gestures.json"

list_commands() {
    hexecute --list 2>/dev/stdout | tail -n +2 | sed 's/^[[:space:]]*//'
}

select_command() {
    {
        echo "!New"
        list_commands
    } | fzf --prompt="Select gesture command: " --border
}

demo() {
    echo "Gimme a sec..."
    local cmd="$1"
    local points
    points=$(jq -r --arg cmd "$cmd" '
        .[] | select(.command == $cmd) | .templates[0][] | "\(.X) \(.Y)"
    ' "$GESTURE_FILE")

    if [[ -z "$points" ]]; then
        echo "No matching command or template found for: $cmd"
        return 1
    fi

    # Compute bounds using awk for floating point
    local minx=999999 maxx=-999999 miny=999999 maxy=-999999

    while read -r x y; do
        minx=$(awk -v a="$minx" -v b="$x" 'BEGIN{print (b<a)?b:a}')
        maxx=$(awk -v a="$maxx" -v b="$x" 'BEGIN{print (b>a)?b:a}')
        miny=$(awk -v a="$miny" -v b="$y" 'BEGIN{print (b<a)?b:a}')
        maxy=$(awk -v a="$maxy" -v b="$y" 'BEGIN{print (b>a)?b:a}')
    done <<< "$points"

    local pad=5
    minx=$(awk -v a="$minx" -v p="$pad" 'BEGIN{print a-p}')
    miny=$(awk -v a="$miny" -v p="$pad" 'BEGIN{print a-p}')
    maxx=$(awk -v a="$maxx" -v p="$pad" 'BEGIN{print a+p}')
    maxy=$(awk -v a="$maxy" -v p="$pad" 'BEGIN{print a+p}')

    # Compute width/height
    local width height
    width=$(awk -v a="$minx" -v b="$maxx" 'BEGIN{print b-a}')
    height=$(awk -v a="$miny" -v b="$maxy" 'BEGIN{print b-a}')

    # Build SVG path
    local path=""
    local first=1
    while read -r x y; do
        if (( first )); then
            path+="M $x $y "
            first=0
        else
            path+="L $x $y "
        fi
    done <<< "$points"

    # Output SVG
    cat > /tmp/out.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="$minx $miny $width $height"
     width="400" height="400">

  <defs>
    <marker id="arrow"
            markerWidth="4" markerHeight="4"
            refX="2.5" refY="2"
            orient="auto"
            markerUnits="strokeWidth">
      <path d="M0 1Q0-1 2 1C3 2 3 2 2 3Q0 5 0 3" fill="red" />
    </marker>
  </defs>

  <path d="$path"
        fill="none"
        stroke="black"
        stroke-width="4"
        stroke-linecap="round"
        stroke-linejoin="round"
        marker-mid="url(#arrow)" />
</svg>
EOF

    zen --private-window /tmp/out.svg
}


action_menu() {
    local cmd="$1"
    printf "%s\n" \
        "Demonstrate" \
        "Edit" \
        "Delete" \
        "Exit" \
        "Cancel" |
    fzf --prompt="Action for '$cmd': " --border
}

# Main loop
main() {
    while true; do
        cmd=$(select_command)
        [[ -z "$cmd" ]] && break

        if [[ "$cmd" == "!New" ]]; then
            hexecute --list
            echo "Enter new command:"
            echo -n "> "
            read -r newcmd
            hexecute --learn "$newcmd"
            continue
        fi

        while true; do
            action=$(action_menu "$cmd")
            case "$action" in
                Demonstrate)
                    demo "$cmd" || true
                    ;;
                Edit)
                    echo "Recreating $cmd"
                    hexecute --remove "$cmd"
                    hexecute --learn "$cmd" || { break; }
                    ;;
                Delete)
                    echo "Deleting $cmd"
                    hexecute --remove "$cmd"
                    break
                    ;;
                Exit)
                    echo "Exiting tool"
                    exit 0
                    ;;
                Cancel|"")
                    break
                    ;;
            esac
        done
    done
}

main

