#!/bin/sh
niri msg action "$1" $(($(niri msg workspaces | tail -n 1 | tail -c +4) - "$2"))
