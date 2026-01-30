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
      name = "navi";
      text = builtins.readFile ./navi.sh;
    })
    (pkgs.writeShellApplication {
      name = "suyaz";
      text = ''sudo yazi "$@"'';
    })

    # The upd scripts
    (pkgs.writeShellApplication {
      name = "upd-garbage";
      text = builtins.readFile ./upd-garbage.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-user";
      text = builtins.readFile ./upd-user.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-user-garbage";
      text = "upd-garbage;upd-user";
    })
    (pkgs.writeShellApplication {
      name = "upd-system";
      text = builtins.readFile ./upd-system.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-system-garbage";
      text = "sudo upd-garbage;upd-system";
    })
    (pkgs.writeShellApplication {
      name = "upd-all";
      text = builtins.readFile ./upd-all.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-all-garbage";
      text = "sudo upd-garbage;upd-all";
    })
  ];

  # Extra scripts that need to go in /bin
  system.activationScripts.text = ''
ln -sf ${pkgs.bash}/bin/bash /bin/bash
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
