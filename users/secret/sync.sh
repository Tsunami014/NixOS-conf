USER="grapefru14" /etc/nixos/users/grapefru14/sync.sh delold
/etc/nixos/users/grapefru14/sync.sh

sed -i '$i\
protonvpn-app --start-minimized &

' "$HOME/,sysfiles/,startup.sh"
