#!/bin/sh

lock &
quickshell -c bar -n &

sleep 0.5

awww-daemon &

~/.,sysfiles/idle.sh &
~/.,sysfiles/autorotate.sh &
~/.,sysfiles/gestures.sh &

wl-paste --watch cliphist store &

weather-daemon &
ollama serve &

kando >/tmp/kando.log 2>&1 &
kdeconnect-indicator &

disown
