#!/bin/sh
exec > /tmp/autorotate.log 2>&1
set -x
get_outp() {
  if [ "${1-}" ]; then
    OUTPUT="$1"
  else
    OUTPUT="$(niri msg outputs | grep -Po -m 1 '(?<=Output ")[^"]+')"
  fi
}
get_outp
if [ "$OUTPUT" = "" ]; then
  echo "Waiting for output..."
  while [ "$OUTPUT" = "" ]; do
    sleep 0.2
    get_outp
  done
fi
echo "Using output '$OUTPUT'"

rotate_output() {
  if [ -f "/tmp/NOAUTOROTATE" ]; then
    echo "Ignoring rotation"
    return
  fi
  orientation="$1"
  case "$orientation" in
    *normal*)
      rot=normal
      ;;
    *right-up*)
      rot=270
      ;;
    *bottom-up*)
      rot=180
      ;;
    *left-up*)
      rot=90
      ;;
    *) echo "Unknown orientation: $orientation" >&2; return ;;
  esac
  matrix="1.0 0.0 0.0 0.0 1.0 0.0"
  echo "Rotating to $rot..."
  niri msg output "$OUTPUT" transform "$rot"
  mkdir -p /tmp/autorotate
  cat > "/tmp/autorotate/rotate.kdl" <<EOF
input {
  touch {
    map-to-output "$OUTPUT"
    calibration-matrix $matrix
  }
  tablet {
    map-to-output "$OUTPUT"
    calibration-matrix $matrix
  }
}
EOF
  umount ~/.config/niri/autorotate 2>/dev/null || true
  bindfs /tmp/autorotate ~/.config/niri/autorotate
}

rotate_output normal

echo "Monitoring..."
monitor-sensor | while IFS= read -r line; do
  case "$line" in
    *"Accelerometer orientation changed:"*)
      rotate_output "$line"
      ;;
    *) ;;
  esac
done
