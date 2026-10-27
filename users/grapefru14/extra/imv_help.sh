#!/bin/sh
if [ "$1" = show ]; then
  cat <<'EOF'
imv keys
========

Custom
  r          Reset zoom and pan
  S          Next upscaling mode
  a          Zoom to 100% and reset rotation
  F1         This help

Navigation
  Left/Right Previous / next image
  gg / G     First / last image
  h j k l    Pan
  c          Center image
  x          Close current image
  :          Command prompt

View
  d          Toggle overlay
  f          Fullscreen
  Up/i/+     Zoom in
  Down/o/-   Zoom out
  s          Next scaling mode
  Ctrl+r     Rotate 90 degrees
  p          Print current path to stdout

Animation / slideshow
  Space      Pause/play gif
  .          Next frame
  t / T      Slideshow start/faster / stop/slower

  q          Quit

EOF
  printf 'Press Enter to close.'
  read -r _ </dev/tty
  exit
fi

sleep 0.1 # Required, otherwise it will spawn the process a million times
exec $TermSpawn "$0" show
