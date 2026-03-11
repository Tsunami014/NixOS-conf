#!/bin/sh
roland --config <(cat << 'EOF'
[[gestures]]
num_fingers = 3
kind = "SwipeLeft"
action = "niri msg action maximize-column"
min_duration = 50
mix_distance = 200.0
on_edge = { Right = 300 }
[[gestures]]
num_fingers = 3
kind = "SwipeUp"
action = "niri msg action fullscreen-window"
min_duration = 50
mix_distance = 200.0
on_edge = { Bottom = 300 }
[[gestures]]
num_fingers = 3
kind = "SwipeDown"
action = "niri msg action open-overview"
min_duration = 50
mix_distance = 200.0
on_edge = { Top = 300 }
[[gestures]]
num_fingers = 4
kind = "Press"
action = "hexecute"
min_duration = 50
max_distance = 20.0
EOF
)
