#!/bin/sh
roland --config <(cat << 'EOF'
[[gestures]]
num_fingers = 3
kind = "SwipeDown"
action = "niri msg action open-overview"
min_duration = 50
mix_distance = 200.0
[[gestures]]
num_fingers = 4
kind = "Press"
action = "hexecute"
min_duration = 50
max_distance = 20.0
EOF
)
