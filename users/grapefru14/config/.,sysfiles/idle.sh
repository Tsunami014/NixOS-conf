#!/bin/sh
swayidle -w \
    timeout 300 'systemctl suspend' \
    before-sleep 'lock &'
