if ! [ -d $(dirname "$HOME") ]; then
  echo "Home directory does not exist!"
fi

# So it doesn't potentially cause issues
umount ~/.config/niri/autorotate 2>/dev/null || true

[ "${1-}" = "copyover" ] && copyover=true || copyover=false
mkdir -p "$HOME/.config" "$HOME/.local/share"
mainFold="/etc/nixos/users/$USER"
for fold in "$mainFold"/*/ "$mainFold"/.*/; do
  if [ ! -f "$fold/list.txt" ]; then
    continue
  fi
  if ! $copyover; then
    chmod +r -R "$fold"
  fi
  while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    read -r mutable prefix name <<< "$line"

    if [ "$mutable" = "#" ]; then
      continue
    fi
  
    orig="$fold$name"
    if [ ! -d "$orig" ]; then
      echo "Original config does not exist for '$name'"
      continue
    fi
    if [ "$mutable" = "perm" ]; then
      prt="Permanent "
    elif [ "$mutable" = "mut" ]; then
      prt="Mutable "
    else
      echo "Skipping unknown mutability for '$line': $mutable"
      continue
    fi

    prt+="$name "

    if [ "$prefix" = "conf" ]; then
      link="$HOME/.config"
      prt+="in ~/.config"
    elif [ "$prefix" = "shr" ]; then
      link="$HOME/.local/share"
      prt+="in ~/.local/share"
    elif [ "$prefix" = "home" ]; then
      link="$HOME"
      prt+="in ~/"
    else
      link="$HOME/$prefix"
      prt+="in ~/$prefix"
    fi

    if $copyover; then
      doin="Copying over"
    else
      doin="Linking"
    fi

    printf "%s\e[1m%s\e[0m%s\n" "$doin config for " "$prt" "..."
    if [ -d "$link/$name" ] && [ ! -L "$link/$name" ] && ! $copyover; then
      echo "Config already exists!"
      printf "Old: $link/$name  \tNew: $orig\n"
      printf "Opts: \tq: quit\n\tb: backup old & combine \tB: backup old & delete\n\tc: combine \td: delete old\n"
      while true; do
        read -sn1 -p "What do you want to do? " OPT < /dev/tty
        printf "\n\e[K"
        case "$OPT" in
          b|B)
            echo "Backing up existing config..."
            cp -r "$link/$name" "$link/$name.backup"
            ;;
          c|d);;
          q)
            echo "Quitting!"
            exit 1
            ;;
          *)
            printf "Unknown option '$OPT'!\e[999D\e[1A\e[K"
            ;;
        esac
        case "$OPT" in
          b|c)
            echo "Syncing existing config..."
            rsync -a --delete "$link/$name/" "$fold/$name/"
            break
          ;;
          B|d) break ;;
        esac
      done
      echo "Replacing config with new..."
    fi
    rm -rf "$link/$name"
    if $copyover; then
      cp -r "$orig" "$link/$name"
    else
      ln -sfT "$orig" "$link/$name"
    fi
  done < "$fold/list.txt"
done
