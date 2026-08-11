{ config, pkgs, lib, inputs, ... }:
{
  home.username = "secret";
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./desktop.nix
    (import ../grapefru14/base.nix { full = false; })

    ../grapefru14/pkgs/yazi/yaz.nix
  ];

  home.packages = with pkgs; [
    lazygit
    fuzzel
    cliphist
    wl-clipboard

    #protonvpn-gui
    #mullvad-vpn
    #tor-browser

    (pkgs.writeShellApplication {
      name = "hyprwrap";
      text = ''
rm -f ~/.config/hypr/keys.conf
touch ~/.config/hypr/keys.conf
exec hyprland
      '';
    })
    (pkgs.writeShellApplication {
      name = "wallppr";
      text = builtins.readFile ../grapefru14/programs/wallppr.sh;
    })
  ];

  services.cliphist = {
    enable = true;
    systemdTargets = [ "config.wayland.systemd.target" ];
  };

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
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

  programs.bash.profileExtra = ''
[[ -f ~/.bashrc ]] && . ~/.bashrc
# Only exec Hyprland if no display is running and you're on TTY2
if [[ -z $DISPLAY && $XDG_VTNR -eq 2 ]]; then
    exec hyprwrap
fi'';
}
