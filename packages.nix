{ pkgs, ... }: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    home-manager
    bindfs
    wineWow64Packages.stable
    xwayland-satellite
    swayidle
    gcc
    git
    wget
    fzf
    yazi
    unzip
    iio-sensor-proxy
    libinput

    # Icon themes (otherwise some icons won't exist)
    hicolor-icon-theme
    papirus-icon-theme

    # Some packages that are useful, so put here as to not duplicate them across users
    lazygit
    fuzzel
    pavucontrol
    cliphist
    wl-clipboard
    jq
    htop
    swayimg
    amberol # Music
    sioyek

    # Various custom commands
    (pkgs.writeShellApplication {
      name = "+";
      text = ''nix-shell --log-format bar-with-logs -p "$@"'';
    })
    (pkgs.writeShellApplication {
      name = "=";
      text = ''nix-shell --log-format bar-with-logs -p "$1" --run "$*"'';
    })

    (pkgs.writeShellApplication {
      name = "fixprinter";
      text = ''
sudo systemctl restart avahi-daemon
sudo systemctl restart cups
'';
    })

    (pkgs.writeShellApplication {
      name = "suyazi";
      text = ''sudo yazi "$@"'';
    })

    (pkgs.writeShellApplication {
      name = "linkfile";
      text = ''
mkdir -p /tmp/Link
chmod 0775 /tmp/Link 2&>/dev/null || true
cd /tmp/Link
nvim "$USER".md -c 'exe "Neotree"|wincmd w'
'';
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
      name = "upd-sync";
      text = ''bash /etc/nixos/users/"$USER"/sync.sh'';
    })

    (pkgs.writeShellApplication {
      name = "dirinit";
      text = builtins.readFile ./programs/dirinit.sh;
    })
    (pkgs.writeShellApplication {
      name = "close";
      text = builtins.readFile ./programs/close.sh;
    })

    # Lazily loaded
    (pkgs.writeScriptBin "neofetch" ''nix-shell --log-format bar-with-logs -p hyfetch -p fastfetch --run "hyfetch $@"'')
  ];

  programs.bash = {
    enable = true;

    interactiveShellInit = ''
      alias q=exit

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
    dejavu_fonts
    ipafont
    kochi-substitute
    nerd-fonts.ubuntu
    nerd-fonts.adwaita-mono
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  # Unfortunately, steam must be installed globally
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
}
