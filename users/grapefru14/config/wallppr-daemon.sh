#!/bin/sh
swww-daemon &
DAEMON_PID=$!
trap "kill $DAEMON_PID" EXIT
while true; do
    wallppr rand
    sleep 600
done
