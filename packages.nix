{ pkgs, ... }:
let
  updLib = builtins.readFile ./programs/lib.sh;
  mkUpd = name: pkgs.writeShellApplication {
    inherit name;
    text = updLib + "\n" + builtins.readFile ./programs/${name}.sh;
    # lib.sh defines helpers that not every script uses
    excludeShellChecks = [ "SC2329" "SC2034" ];
  };
in {
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
    imv
    amberol # Music
    sioyek

    # Various custom commands
    nix-output-monitor
    (pkgs.writeShellApplication {
      name = "+";
      text = ''nom-shell -p "$@"'';
    })
    (pkgs.writeShellApplication {
      name = "++";
      text = ''nix-shell --log-format bar-with-logs -p "$@"'';
    })
    (pkgs.writeShellApplication {
      name = "=";
      text = ''nom-shell -p "$1" --run "$*"'';
    })
    (pkgs.writeShellApplication {
      name = "==";
      text = ''nix-shell --log-format bar-with-logs -p "$1" --run "$*"'';
    })

    (pkgs.writeShellApplication {
      name = "fixprinter";
      text = ''
sudo systemctl restart avahi-daemon
sudo systemctl restart cups
'';
    })

    # Wrappers with slightly more complex functionality
    (pkgs.writeShellApplication {
      name = "suyazi";
      text = ''sudo yazi "$@"'';
    })
    (pkgs.writeShellApplication {
      name = "imvd"; # imvd a directory but sorted properly
      text = ''
target=$(realpath -- "''${1:-.}") || exit
if [[ -d $target ]]; then
  dir=$target
else
  dir=$(dirname -- "$target")
fi

mapfile -d "" files < <(
  find "$dir" -maxdepth 1 -type f ! -name '.*' -print0 | LC_ALL=C sort -z -f
)

if [[ -d $target ]]; then
  exec imv "''${files[@]}"
else
  exec imv -n "$target" "''${files[@]}"
fi
'';
    })

    (pkgs.writeShellApplication {
      name = "linkfile";
      text = ''
mkdir -p /tmp/Link
chmod 0775 /tmp/Link 2>/dev/null || true
cd /tmp/Link
nvim "$USER".md -c 'exe "Neotree"|wincmd w'
'';
    })

    # The upd scripts (all share ./programs/lib.sh for the pretty output)
    (mkUpd "upd-user")
    (mkUpd "upd-system")
    (mkUpd "upd-all")
    (mkUpd "upd-generations")
    (mkUpd "upd-garbage")
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
    (pkgs.writeShellApplication {
      name = "fetch";
      text = ''nom-shell -p hyfetch -p fastfetch --run "hyfetch ''${*@Q}"'';
    })
  ];

  programs.bash = {
    enable = true;

    interactiveShellInit = ''
alias q=exit
alias :q=exit

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
    return 0
  fi
  if [[ $PWD == /mnt* ]]; then
    cd ~
  fi
  sudo umount -R /mnt
}
_mnt_complete() {
  local cur disks
  cur="''${COMP_WORDS[COMP_CWORD]}"
  disks=$(
    lsblk -ln -o NAME,TYPE |
    awk '$2 == "part" || $2 == "disk" { print $1 }'
  )

  COMPREPLY=( $(compgen -W "$disks" -- "$cur") )
}

complete -F _mnt_complete mnt

_upd_complete() {
    local cmd=''${COMP_WORDS[0]} cur=''${COMP_WORDS[COMP_CWORD]} prev=''${COMP_WORDS[COMP_CWORD-1]}
    local opts

    case "$cmd" in
        dirinit)
            # Template first, then a flag (the script only reads flags from $2)
            if (( COMP_CWORD == 1 )); then
                opts="blank nix rust py pyadv pyvenv cmake cmakeQt help -h --help"
            elif (( COMP_CWORD == 2 )); then
                opts="--force --show"
            else
                return
            fi
            ;;
        upd-garbage)
            # -k / --keep takes a value
            if [[ $prev == -k || $prev == --keep ]]; then
                mapfile -t COMPREPLY < <(compgen -W "7d 14d 30d all" -- "$cur")
                return
            fi
            opts="-h --help -k --keep $("$cmd" --map | cut -d= -f1)"
            ;;
        upd-generations)
            # No --map of its own; it accepts upd-system's flags
            opts="-h --help old -usr -root $(upd-system --map | cut -d= -f1)"
            ;;
        *)
            opts="-h --help $("$cmd" --map | cut -d= -f1)"
            ;;
    esac

    mapfile -t COMPREPLY < <(compgen -W "$opts" -- "$cur")
}

complete -F _upd_complete dirinit upd-all upd-system upd-user upd-garbage upd-generations
  '';
  };

  # Link bash to /bin
  systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash" ];

  programs.direnv.enable = true;

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
