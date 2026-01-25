#!/bin/sh
swayidle -w \
    timeout 300 'systemctl suspend' \
    timeout 480 'hyprlock' \
    before-sleep 'hyprlock'
