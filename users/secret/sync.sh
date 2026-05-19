USER="grapefru14" /etc/nixos/users/grapefru14/sync.sh copyover
/etc/nixos/users/grapefru14/sync.sh

echo '# Commands
- `tor-browser` - launch tor
- `protonvpn-app` - launch proton vpn
' > "$HOME"/info.md

sed -i -e 's/.*hyprlock &.*//' -e '$i\
alacritty -e nvim "$HOME/info.md" -c "exe \\"ToggleTerm\\"|wincmd w"

' "$HOME/,sysfiles/,startup.sh"
