{ config, pkgs, master-pkgs, lib, inputs, ... }: {
  home.file = {
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

  home.activation.niriStubs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    dir="$HOME/.niriextra"
    mkdir -p "$dir"

    mk_files=(
      "autorotate.kdl"
      "animations.kdl"
    )
    for f in "''${mk_files[@]}"; do
      [ -e "$dir/$f" ] || : > "$dir/$f"
    done
  '';

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
      # else
      #   git -C "$fold" pull --ff-only
      fi
    done
  '';
}
