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
for fold in "$mainFold"/*/; do
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
      willb="combined with existing config"
      perm=true
    elif [ "$mutable" = "mut" ]; then
      prt="Mutable "
      willb="deleted"
      perm=false
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
      echo "Config already exists, and will be $willb!"
      while true; do
        read -sn1 -p "What do you want to do? [b - backup, d - delete, q - quit] " OPT < /dev/tty
        printf "\n\e[K"
        case "$OPT" in
          b)
            echo "Backing up!"
            cp -r "$link/$name" "$link/$name.backup"
            break
            ;;
          d)
            echo "Deleting!"
            break
            ;;
          q)
            echo "Quitting!"
            exit 1
            ;;
          *)
            printf "Unknown option '$OPT'!\e[999D\e[1A\e[K"
            ;;
        esac
      done
      if [ "$perm" = false ]; then
        echo "Syncing existing config..."
        rsync -a --delete "$link/$name/" "$fold/$name/"
      fi
    fi
    rm -rf "$link/$name"
    ln -sfT "$orig" "$link/$name"
  done < "$fold/list.txt"
done
