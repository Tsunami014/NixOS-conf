if ! [ -d "$(dirname "$HOME")" ]; then
  echo "Home directory does not exist!"
fi

SysApps="/run/current-system/sw/share/applications/"
LocalApps="$HOME/.local/share/applications"
mkdir -p "$LocalApps"

while IFS= read -r line || [ -n "$line" ]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  sys_file="$SysApps/$line.desktop"
  local_file="$LocalApps/$line.desktop"

  # Handle the launcher shortcut
  if [ ! -f "$local_file" ] && [ -f "$sys_file" ]; then
    cp "$sys_file" "$local_file"
    printf "%s\e[1m%s\e[0m%s\n" "Copied system shortcut for " "$line" "!"
  elif [ ! -f "$local_file" ]; then
    printf "%s\e[1m%s\e[0m%s\n" "Could not find " "$line" " in system folders"
    continue
  fi

  # Inject terminal right after the 'Exec=' key
  if ! grep -q "Exec=.*kitty" "$local_file"; then
    sed -i 's/^Exec=/Exec=kitty -- /' "$local_file"
    printf "%s\e[1m%s\e[0m%s\n" "Prefixed execution terminal for " "$line" "!"
  fi

  # Change Terminal=true to Terminal=false
  if grep -q "^Terminal=true" "$local_file"; then
    sed -i 's/^Terminal=true/Terminal=false/' "$local_file"
    printf "%s\e[1m%s\e[0m%s\n" "Changed terminal flag for " "$line" "!"
  fi
done < /etc/nixos/users/"$USER"/launches.txt
