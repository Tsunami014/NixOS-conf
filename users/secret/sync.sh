#!/usr/bin/env bash
# Commands:
# -term - Run the app in a terminal
# -hide - Hide the entry
# -name <words...> - Override the displayed name (uses all words until next flag)

# To find applications look under $SysApps

if ! [ -d "$(dirname "$HOME")" ]; then
  echo "Home directory does not exist!"
fi

SysApps="/run/current-system/sw/share/applications"
LocalApps="$HOME/.local/share/applications"
mkdir -p "$LocalApps"

while IFS= read -r line || [ -n "$line" ]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  # Split the line on whitespace: first token is the app id, the rest are commands/args
  read -ra tokens <<< "$line"
  app_id="${tokens[0]}"

  printf "\e[1m%s\e[0m%s\n" "Updating desktop file for $app_id" "..."

  sys_file="$SysApps/$app_id.desktop"
  local_file="$LocalApps/$app_id.desktop"

  # Handle the launcher shortcut
  if [ ! -f "$local_file" ] && [ -f "$sys_file" ]; then
    cp "$sys_file" "$local_file"
    echo "Copied system shortcut"
  elif [ ! -f "$local_file" ]; then
    echo "Could not find in system folders!"
    continue
  fi

  # --- Parse the commands for this line ---
  do_term=0
  do_hide=0
  have_name=0
  new_name=""

  i=1
  n=${#tokens[@]}
  while [ "$i" -lt "$n" ]; do
    case "${tokens[$i]}" in
      -term)
        do_term=1
        i=$((i + 1))
        ;;
      -hide)
        do_hide=1
        i=$((i + 1))
        ;;
      -name)
        i=$((i + 1))
        name_words=()
        while [ "$i" -lt "$n" ] && [[ "${tokens[$i]}" != -* ]]; do
          name_words+=("${tokens[$i]}")
          i=$((i + 1))
        done
        if [ "${#name_words[@]}" -eq 0 ]; then
          echo "Warning: -name given with no value, ignoring" >&2
        else
          new_name="${name_words[*]}"
          have_name=1
        fi
        ;;
      *)
        echo "Warning: unknown command '${tokens[$i]}', ignoring" >&2
        i=$((i + 1))
        ;;
    esac
  done

  # --- Apply -term: inject terminal right after the 'Exec=' key ---
  if [ "$do_term" -eq 1 ]; then
    if ! grep -q "^Exec=.*kitty" "$local_file"; then
      sed -i 's/^Exec=/Exec=kitty -- /' "$local_file"
      echo "Prefixed execution terminal"
    fi
    if grep -q "^Terminal=true" "$local_file"; then
      sed -i 's/^Terminal=true/Terminal=false/' "$local_file"
      echo "Changed terminal flag"
    fi
  fi

  # --- Apply -hide: hide from the menu ---
  if [ "$do_hide" -eq 1 ]; then
    if grep -q "^NoDisplay=" "$local_file"; then
      sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$local_file"
    else
      printf 'NoDisplay=true\n' >> "$local_file"
    fi
    echo "Hidden from menu"
  fi

  # --- Apply -name: override every Name field (drop locale variants too) ---
  if [ "$have_name" -eq 1 ]; then
    awk -v name="$new_name" '
      BEGIN { inserted = 0 }
      /^Name(\[[^]]*\])?=/ { next }
      /^\[Desktop Entry\]/ && !inserted {
        print
        print "Name=" name
        inserted = 1
        next
      }
      { print }
    ' "$local_file" > "${local_file}.tmp" && mv "${local_file}.tmp" "$local_file"
    echo "Renamed to \"$new_name\""
  fi
done < /etc/nixos/users/"$USER"/launches.txt
