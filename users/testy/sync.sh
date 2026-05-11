if [ "${1-}" = "before" ]; then
  echo "Skipping before sync"
  exit 0
fi
USER="grapefru14" /etc/nixos/users/grapefru14/sync.sh delold
/etc/nixos/users/grapefru14/sync.sh
