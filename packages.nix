{ pkgs, ... }: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    home-manager
    wine
    xwayland-satellite
    swayidle
    gcc
    git
    wget
    fzf
    yazi
    iio-sensor-proxy

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
      text = builtins.readFile ./programs/navi.sh;
    })
    (pkgs.writeShellApplication {
      name = "suyazi";
      text = ''sudo yazi "$@"'';
    })

    # The upd scripts
    (pkgs.writeShellApplication {
      name = "upd-user";
      text = builtins.readFile ./programs/upd-user.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-system";
      text = builtins.readFile ./programs/upd-system.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-all";
      text = builtins.readFile ./programs/upd-all.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-generations";
      text = builtins.readFile ./programs/upd-generations.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-garbage";
      text = builtins.readFile ./programs/upd-garbage.sh;
    })
    (pkgs.writeShellApplication {
      name = "user-sync";
      text = ''bash ${./users}/"$USER"/sync.sh'';
    })

    (pkgs.writeShellApplication {
      name = "dirinit";
      text = builtins.readFile ./programs/dirinit.sh;
    })
  ];

  programs.bash = {
    enable = true;

    interactiveShellInit = ''
      mnt() {
        [[ $PWD == /mnt* ]] && cd ~

        mountpoint /mnt -q && sudo umount -R /mnt

        if [[ -z "$1" ]]; then
          echo "usage: mnt <device>"
          return 1
        fi

        sudo mount "/dev/$1" /mnt \
          -o uid="$(id -u)",gid="$(id -g)"

        cd /mnt
      }
      umnt() {
        if ! mountpoint /mnt -q; then
          echo "No mount in /mnt!"
          exit 0
        fi
        if [[ $PWD == /mnt* ]]; then
          cd ~
        fi
        sudo umount -R /mnt
      }
      _mnt_complete() {
        local cur
        cur="''${COMP_WORDS[COMP_CWORD]}"
        disks=$(
          lsblk -ln -o NAME,TYPE |
          awk '$2 == "part" || $2 == "disk" { print $1 }'
        )

        COMPREPLY=( $(compgen -W "$disks" -- "$cur") )
      }

      complete -F _mnt_complete mnt
  '';
  };

  programs.direnv.enable = true;

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
