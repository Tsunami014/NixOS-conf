{ config, pkgs, lib, inputs, ... }:
{
  home.username = "secret";
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  imports = [
    (import ../grapefru14/base.nix { full = false; })
  ];

  home.packages = with pkgs; [
    kitty
    #protonvpn-gui
    #mullvad-vpn
    #tor-browser
  ];

  programs.caelestia = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
      environment = [];
    };
    settings = {
      bar.statusIcons = [
        { id = "lockStatus"; enabled = true; }
        { id = "network"; enabled = true; }
        { id = "bluetooth"; enabled = true; }
        { id = "battery"; enabled = false; }
      ];
      paths.wallpaperDir = "/etc/nixos/users/grapefru14/backgrounds/";
    };
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = {
        theme.enableGtk = false;
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      exec-once = [
        "caelestia shell -d"
      ];

      bind = [
        "$mod, RETURN, exec, ${pkgs.kitty}/bin/kitty"
        "$mod, Q, killactive,"
        "$mod, M, exit,"
        "$mod, V, togglefloating,"

        # Move focus
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
      ];
    };
  };

  home.activation.makeFolders = config.lib.dag.entryAfter [ "writeBoundary" ]
    ''cd "$HOME"; mkdir -p Downloads Documents Pictures Videos'';

  home.activation.cloneConfigs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    PATH=${pkgs.git}/bin:$PATH
    declare -A files
    files["$HOME/.config/nvim"]="https://github.com/Tsunami014/nvimConfig"

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
