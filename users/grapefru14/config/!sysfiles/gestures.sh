#!/bin/sh
roland --config <(cat << 'EOF'
[[gestures]]
num_fingers = 4
kind = "Press"
action = "hexecute"
min_duration = 50
max_distance = 20.0
EOF
)
