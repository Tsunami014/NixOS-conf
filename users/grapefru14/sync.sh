if [ "${1-}" = "before" ]; then
  echo "Skipping before sync"
  exit 0
fi
if ! [ -d $(dirname "$HOME") ]; then
  echo "Home directory does not exist!"
fi
mkdir -p "$HOME/.config" "$HOME/.local/share"
mainFold="/etc/nixos/users/$USER"
folders=("/config")
for fold in "$mainFold"/*/ "$mainFold"/.*/; do
  if [ ! -f "$fold/list.txt" ]; then
    continue
  fi
  chmod +r -R "$fold"
  while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    read -r mutable prefix name <<< "$line"

    if [ "$mutable" = "#" ]; then
      continue
    fi
  
    orig="$fold/$name"
    if [ ! -d "$orig" ]; then
      mkdir "$orig"
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

    printf "%s\e[1m%s\e[0m%s\n" "Linking config for " "$prt" "..."
    if [ -d "$link/$name" ] && [ ! -L "$link/$name" ]; then
      echo "Config already exists!"
      printf "Opts: \tq: quit\n\tb: backup & combine \tB: backup and delete old\n\tc: combine \td: delete old\n"
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
    ln -sfT "$orig" "$link/$name"
  done < "$fold/list.txt"
done
