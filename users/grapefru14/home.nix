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

  # Allow bluetooth headphones buttons to control media
  services.mpris-proxy.enable = true;

  # Package stuff
  imports = [
    ./browser.nix
  ];

  home.packages = with pkgs; [
    alacritty
    yazi
    htop
    gh
    lazygit
    cliphist
    wl-clipboard
    fuzzel
    jq

    inputs.hexecute.packages.${system}.default
    # Various apps
    pavucontrol
    gnome-calculator
    (pkgs.callPackage ./extraPkgs/godsvg.nix {})

    # Quickshell & quickshell projects
    inputs.qml-niri.packages.${system}.quickshell
    inputs.qml-niri.packages.${system}.default
    acpi
    brightnessctl
    inputs.hyprlock.packages.${system}.default

    # For neovim
    tree-sitter
    unzip
    nodejs
    fd

    # Extra executable stuff
    (pkgs.writeShellApplication {
      name = "navihex";
      text = builtins.readFile ./navihex.sh;
    })
    swww
    (pkgs.writeShellApplication {
      name = "wallppr";
      text = builtins.readFile ./wallppr.sh;
    })
  ];

  services.kdeconnect.enable = true;

  services.cliphist = {
    enable = true;
    systemdTargets = [ "config.wayland.systemd.target" ];
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
alias downloads="mkdir /tmp/Download 2>/dev/null;cd /tmp/Download"
'';
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

  home.file."Pictures/backgrounds" = {
    source = ./backgrounds;
    recursive = true;
  };

  home.file.".local/share/fonts" = {
    source = ./fonts;
    recursive = true;
  };

  xdg.configFile = let
      configDirs =
        if builtins.pathExists ./config then
          builtins.attrNames (builtins.readDir ./config)
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

  home.activation.makeFolders = config.lib.dag.entryAfter [ "writeBoundary" ]
    ''cd "$HOME"; mkdir -p Downloads Documents Pictures Videos'';

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
