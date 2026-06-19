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
      fi
    done
  '';
}
