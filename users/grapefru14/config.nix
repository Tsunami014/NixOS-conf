{ config, pkgs, master-pkgs, lib, inputs, ... }: {
  home.file = {
    "Pictures/backgrounds" = {
      source = ./backgrounds;
      recursive = true;
    };

    ".local/share/fonts" = {
      source = ./fonts;
      recursive = true;
    };
  }
    // lib.optionalAttrs (lib.pathExists ./apps) {
      "AppIms" = {
        source = ./apps;
        recursive = true;
      };
    };


  home.activation.makeFolders = config.lib.dag.entryAfter [ "writeBoundary" ]
    ''cd "$HOME"; mkdir -p Downloads Documents Pictures Videos'';

  home.activation.cloneConfigs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    PATH=${pkgs.git}/bin:$PATH
    declare -A files
    files["$HOME/.config/nvim"]="https://github.com/Tsunami014/nvimConfig"
    files["$HOME/.config/quickshell/bar"]="https://github.com/Tsunami014/bar"

    for fold in "''${!files[@]}"; do
      echo "$fold"
      name=$(basename "$fold")

      if [ ! -d "$fold" ]; then
        echo "Cloning $name config repo..."
        mkdir -p $(dirname "$fold")
        git clone "''${files[$fold]}" "$fold"
      else
        echo "Updating $name config..."
        git -C "$HOME/.config/nvim" pull || true
      fi
    done

    projects="$HOME/.config/nvim/projects.json"
    [ ! -f "$projects" ] && echo '{"projects": ["/etc/nixos/users/$USER", "/etc/nixos"]}' > "$projects"
  '';


  # Link the config to the correct places
  home.activation.makeLinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
  if ! [ -d "$HOME" ]; then
    echo "Home directory does not exist!"
  fi
  mainFold="/etc/nixos/users/$USER/config"
  chmod +rw -R "$mainFold"
  dots="$HOME/.dots"
  mkdir -p "$dots" "$HOME/.config" "$HOME/.local/share"
  while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    read -r mutable prefix name <<< "$line"

    src="$mainFold/$name"
    if [ ! -d "$src" ]; then
      mkdir "$src"
    fi
    if [ "$mutable" = "perm" ]; then
      orig="${./config}/$name"
      prt="Permanent "
    elif [ "$mutable" = "mut" ]; then
      orig="$src"
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
    else
      echo "Skipping unknown prefix for '$line': $prefix"
      continue
    fi

    printf "%s\e[1m%s\e[0m%s\n" "Linking config for " "$prt" "..."
    if [ -d "$link/$name" ] && [ ! -L "$link/$name" ]; then
      echo "Using existing config..."
      ${pkgs.rsync}/bin/rsync -a --delete "$link/" "$mainFold/$name/"
    fi
    rm -rf "$link/$name"
    ln -sfT "$orig" "$link/$name"
  done < "${./config/list.txt}"
  '';
}
