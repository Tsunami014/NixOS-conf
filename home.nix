{ config, pkgs, inputs, ... }: {
  home.username = "grapefru14";
  home.homeDirectory = "/home/grapefru14";
  home.stateVersion = "25.11";

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
  };

  # Package stuff
  imports = [
    ./browser.nix
  ];

  home.packages = with pkgs; [
    yazi
    htop
    lazygit
    cliphist
    wl-clipboard
    fzf
    fuzzel

    inputs.hexecute.packages.${system}.default

    # Quickshell & quickshell projects
    inputs.qml-niri.packages.${system}.quickshell
    inputs.qml-niri.packages.${system}.default
    acpi

    # For neovim
    tree-sitter
    unzip
    nodejs
    fd

    # Extra executable stuff
    (pkgs.writeShellApplication {
      name = "+";
      text = ''nix-shell -p "$@"'';
    })
    (pkgs.writeShellApplication {
      name = "=";
      text = ''nix-shell -p "$1" --run "$*"'';
    })
    (pkgs.writeShellApplication {
      name = "sync-config";
      text = builtins.readFile ./sync-config.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd";
      text = "sudo -v;sync-config;sudo nixos-rebuild switch";
    })
    (pkgs.writeShellApplication {
      name = "upd-garbage";
      text = "sudo nix-collect-garbage -d;upd";
    })
    (pkgs.writeShellApplication {
      name = "navi";
      text = builtins.readFile ./navi.sh;
    })
    (pkgs.writeShellApplication {
      name = "navihex";
      text = builtins.readFile ./navihex.sh;
    })
  ];

  services.cliphist = {
    enable = true;
    systemdTargets = [ "config.wayland.systemd.target" ];
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    # bashrcExtra = '' file contents ''
    profileExtra = ''
[[ -f ~/.bashrc ]] && . ~/.bashrc
# Only exec Niri if no display is running and you're on TTY1
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec niri
fi'';
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "Tsunami014";
        email = "tsunami014@duck.com";
      };
      init.defaultBranch = "main";
    };
  };
  # So setting global git config sets onto this writable empty file, not the unwritable git config defined above
  home.activation.makeGitConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    touch "$HOME/.gitconfig"
  '';

  # Config stuff

  xdg.configFile = let
      configDirs =
        if builtins.pathExists ./config then
          builtins.filter
            (name: (builtins.readDir ./config)."${name}" == "directory")
            (builtins.attrNames (builtins.readDir ./config))
        else [];
    in
      builtins.listToAttrs (
        map (name: {
          name = name;
          value = {
            source = ./config/${name};
            recursive = true;
          };
        }) configDirs
      );

  home.activation.copyConfigMut = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    for dir in "${./configMut}"/*; do
      [ -d "$dir" ] || continue
      name="$(basename "$dir")"
      mkdir -p "$HOME/.config/$name"
      ${pkgs.rsync}/bin/rsync -a --delete "$dir/" "$HOME/.config/$name/"
      chmod +rw -R "$HOME/.config/$name/"
    done
  '';

  home.activation.cloneNvim = config.lib.dag.entryAfter [ "checkLinkTargets" ] ''
    PATH=${pkgs.git}/bin:$PATH
    if [ ! -d "$HOME/.config/nvim" ]; then
      echo "Cloning Neovim config repo..."
      mkdir -p "$HOME/.config"
      git clone https://github.com/Tsunami014/nvimConfig "$HOME/.config/nvim"
      echo '{"projects": ["/etc/nixos"]}' > "$HOME/.config/nvim/projects.json"
    else
      echo "Updating Neovim config..."
      git -C "$HOME/.config/nvim" pull
    fi
  '';
  home.activation.cloneBar = config.lib.dag.entryAfter [ "checkLinkTargets" ] ''
    PATH=${pkgs.git}/bin:$PATH
    if [ ! -d "$HOME/.config/quickshell/bar" ]; then
      echo "Cloning Bar config repo..."
      mkdir -p "$HOME/.config/quickshell/bar"
      git clone https://github.com/Tsunami014/bar "$HOME/.config/quickshell/bar/"
    else
      echo "Updating Bar config..."
      git -C "$HOME/.config/quickshell/bar" pull
    fi
  '';
}
