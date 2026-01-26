{ pkgs, ... }:
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    home-manager
    xwayland-satellite
    swayidle
    gcc
    git
    wget
    fzf

    # Printer stuff
    (pkgs.writeShellApplication {
      name = "printer-settings";
      text = "zen --private-window http://localhost:631";
    })

    # Various custom commands
    (pkgs.writeShellApplication {
      name = "+";
      text = ''nix-shell -p "$@"'';
    })
    (pkgs.writeShellApplication {
      name = "=";
      text = ''nix-shell -p "$1" --run "$*"'';
    })

    (pkgs.writeShellApplication {
      name = "upd-user";
      text = builtins.readFile ./upd-user.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-user-garbage";
      text = ''
printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
nix-collect-garbage -d
upd-user
'';
    })
    (pkgs.writeShellApplication {
      name = "upd-system";
      text = builtins.readFile ./upd-system.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-system-garbage";
      text = ''
sudo -v
printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
sudo nix-collect-garbage -d
upd-system
'';
    })
    (pkgs.writeShellApplication {
      name = "upd-all";
      text = builtins.readFile ./upd-all.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-all-garbage";
      text = ''
sudo -v
printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
sudo nix-collect-garbage -d
upd-all
'';
    })
  ];

  system.activationScripts.text = ''
ln -sf ${pkgs.bash}/bin/bash /bin/bash
ln -sf ${./navi.sh} /bin/navi
'';

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
