USER="grapefru14" /etc/nixos/users/grapefru14/sync.sh delold
/etc/nixos/users/grapefru14/sync.sh

echo '# Commands
- `tor-browser` - launch tor
- `protonvpn-app` - launch proton vpn' > "$HOME"/info.md

sed -i '$i\
nvim "$HOME/info.md"

' "$HOME/,sysfiles/,startup.sh"
